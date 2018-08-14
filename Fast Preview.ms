/*---------------------------------------------------------------
Name: Fast Preview v1.0

Description:
This script renders animated previews in a separate 3ds Max session.
Objects are rendered as boxes, speeding up rendering while still giving
a good sense of camera movement.

Dependencies:
...\TCP\
    MaxClient.ms
    MaxServer.ms

Usage:
1. Run the script
2. If “Offline” – press “Begin Session”
3. Wait until the sandbox 3ds Max scene is loaded. It will say “Online!” and go green
4. Select objects to preview (something in the shot, to see the camera speed)
5. Press “Render Preview”
6. You can continue working while the preview is being rendered in the background

Author: Andrej Perfilov [perfilov3d.com]
Date: 21-07-2018
*/---------------------------------------------------------------

includeLocation = getFilenamePath (getThisScriptFilename()) + "TCP\\"
filein (includeLocation + "MAXClient.ms")

try(destroydialog fastPreview)catch()

rollout fastPreview "Fast Preview 1.0" width:152 height:312
(
	button 'btn_begin' "Begin Session" pos:[8,40] width:136 height:40 align:#left
	progressBar 'pb_status' "" pos:[8,8] width:136 height:8 value:100 color:(color 255 255 0) align:#left
	button 'btn_Render' "Render Preview" pos:[8,264] width:136 height:40 enabled:false align:#left
	checkbox 'chk_range' "Set custom range" pos:[16,105] width:112 height:16 checked:false align:#left
	GroupBox 'grp1' "Sequence Settings" pos:[8,88] width:136 height:80 align:#left
	spinner 'spn_from' "" pos:[16,125] width:56 height:16 enabled:false range:[-100000,100000,0] type:#integer scale:1 align:#left
	spinner 'spn_to' "" pos:[80,124] width:56 height:16 enabled:false range:[-100000,100000,0] type:#integer scale:1 align:#left
	label 'lbl_status' "Status: " pos:[8,20] width:136 height:16 align:#left
	label 'lbl_fps' "@ ?? fps" pos:[52,147] width:52 height:16 align:#left
	GroupBox 'grp2' "Quality Settings" pos:[8,176] width:136 height:80 align:#left
	spinner 'spn_boxSegs' "" pos:[88,216] width:48 height:16 range:[500,1e+06,2500] type:#integer scale:500 align:#left
	label 'lbl3' "Box subdivs" pos:[16,216] width:72 height:16 align:#left
	spinner 'spn_resolution' "" pos:[88,200] width:48 height:16 range:[0.1,1,0.5] align:#left
	label 'lbl7' "Resolution" pos:[16,200] width:72 height:16 align:#left
	checkbox 'chk_clay' "Clay Style Render" pos:[15,235] width:120 height:16 checked:true align:#left
	
	local connecting = false
	local previewFile = GetDir #preview + "\\quickPreview.avi"
	local mergeFile = GetDir #autoback + "\\quickPreview.max"
	local scriptFile = GetDir #preview + "\\quickPreview.ms"
	local maxVer = ((maxVersion())[1]/1000)+1998 -- current Max Version
	
	fn writeStringToFileAndReturnCommand str =
	(
		cmd = stringstream ""
		result = createFile scriptFile
		close result
		if result != undefined then
		(
			f = openFile scriptFile mode:"w"
			format str to:f
			close f
			format "fileIn \"%\"" scriptFile to:cmd
		)
		else messagebox "       Could not write script!" title:"Write error!" beep:false
		return cmd as string
	)
	
	fn setFPSLable =
	(
		lbl_fps.text = "@ " + frameRate as string + " fps"
	)
	
	fn isFileUnlocked file =
	(
		try
		(
			if maxVer > 2012 then
			(
				f = openFile file mode:"a"
				close f
			)
			else
			(
				f = createFile file
				close f
			)
		) catch(return false)
		if f != undefined then
			return true
		else
			return false
	)
	
	fn ckeckIfBusy =
	(
		sleep 0.5
		busy = true
		sleepTime = 0.2
		counter = 0
		limit = 120.0
		
		lbl_status.text = "Status: Busy..."
		pb_status.color = yellow
		btn_render.enabled = false
		
		for i = 1 to 10 do -- wait 2 sec to make sure command has gone through
		(
			sleep sleepTime
			windows.processPostedMessages()
		)
		while busy and counter < limit do
		(
			if not (isFileUnlocked previewFile) then
			(
				sleep sleepTime
				counter += sleepTime
				windows.processPostedMessages()
			)
			else
			(
				busy = false
				counter += limit
				lbl_status.text = "Status: Online!"
				pb_status.color = color 0 150 0
				btn_render.enabled = true
			)
		)
	)
	
	fn getCameraRange =
	(
		cam = getactivecamera()
		if cam != undefined then
		(
			if chk_range.checked then
			(
				camStart = spn_from.value
				camEnd = spn_to.value
				return #(camStart, camEnd)
			)
			else
			try
			(
				k = numkeys cam.rotation.controller
					if k != 0 do (CamStart = getkeytime cam.rotation.controller 1)
					if k != 0 do (CamEnd = getkeytime cam.rotation.controller k)
				k = numkeys cam.pos.controller
					if k != 0 do (CamStart = getkeytime cam.pos.controller 1)
					if k != 0 do (CamEnd = getkeytime cam.pos.controller k)
				return #(camStart, camEnd)
			)
			catch
			(
				messagebox "       Can't determine camera range!\n       The camera is either a target camera or is parented to something.\n       Use custom range to manually set the frames." title:"Camera range error" beep:false
				return undefined
			)
		)
		else
		(
			messagebox "Switch to your active camera first!" title:"No active camera found" beep:false
			return undefined
		)
	)
	
	fn buildPreviewScript =
	(
		range = getCameraRange()
		cmd = stringstream ""
		if range != undefined do
		(
			format "animationRange = %;" animationRange to:cmd
			format "frameRate = %;" frameRate to:cmd
			format "preview_name = \"%\";" previewFile to:cmd
			format "view_size = getViewSize()*%;" spn_resolution.value to:cmd
			format "anim_bmp = bitmap view_size.x view_size.y filename:preview_name;" to:cmd
			format "for t = % to % do" range[1] range[2] to:cmd
			format "(" to:cmd
			format "sliderTime = t;" to:cmd
			format "dib = gw.getViewportDib();" to:cmd
			format "copy dib anim_bmp;" to:cmd
			format "save anim_bmp;" to:cmd
			format ");" to:cmd
			format "close anim_bmp;" to:cmd
			format "shellLaunch preview_name \"\";" to:cmd
			format "gc();" to:cmd
		)
		return cmd as string
	)
	
	fn exportCameraAndBuildMergeScript =
	(
		cam = getactivecamera()
		saveNodes #(cam) mergeFile
		cmd = stringstream ""
		format "mergemaxfile \"%\";" mergeFile to:cmd
		format "viewport.setCamera (getnodebyname \"%\");" cam.name to:cmd
		return cmd as string
	)
	
	fn buildViewportStyleScript =
	(
		cmd = stringstream ""
		ngm = NitrousGraphicsManager.GetActiveViewportSetting()
		style = ngm.VisualStyleMode
		format "viewport.setLayout #layout_1;" to:cmd
		format "viewport.setGridVisibility #all %;" (viewport.getGridVisibility 1) to:cmd
		format "viewport.SetRenderLevel %;" (viewport.GetRenderLevel()) to:cmd
		format "viewport.SetShowEdgeFaces %;" (viewport.GetShowEdgeFaces()) to:cmd
		format "viewport.SetTransparencyLevel %;" (viewport.GetTransparencyLevel()) to:cmd
		format "ngm = NitrousGraphicsManager.GetActiveViewportSetting();" to:cmd
		format "ngm.VisualStyleMode = %;" style to:cmd
		format "displayColor.wireframe = #material;" to:cmd
		return cmd as string
	)
	
	fn buildSceneObjectsAsBoxesScript =
	(
		cmd = stringstream ""
		if selection.count != 0 then
		(
			sel = execute "$/selection/*"
			for obj in sel do
			(
				worldSpaceXform = obj.transform
				objectSpaceXform = inverse worldSpaceXform
				scaleX = obj.scale.x
				scaleY = obj.scale.y
				scaleZ = obj.scale.z
				obj.transform *= objectSpaceXform
				L = (obj.max.x - obj.min.x) * scaleX
				W = (obj.max.y - obj.min.y) * scaleY
				H = (obj.max.z - obj.min.z) * scaleZ
				Lsegs = (abs ((L/spn_boxSegs.value) as integer)) + 1
				Wsegs = (abs ((W/spn_boxSegs.value) as integer)) + 1
				Hsegs = abs (((H/spn_boxSegs.value) as integer)) + 1
				obj.transform = worldSpaceXform
				rot = obj.transform.rotation
				piv = obj.pivot
				CenterPivot obj
				boxPos = [obj.pos.x, obj.pos.y, obj.min.z]
				obj.pivot = piv
				format "b = box length:% width:% height:% lengthsegs:% widthsegs:% heightsegs:%;" L W H Lsegs Wsegs Hsegs to:cmd
				format "b.transform = translate (% as matrix3) b.transform.pos;" rot to:cmd
				format "r = b.transform.rotation * (inverse %);" rot to:cmd
				format "b.rotation *= r;" to:cmd
				format "b.pos = %;" boxPos to:cmd
				if chk_clay.checked then
					format "b.wirecolor = color 180 70 70;" to:cmd
				else
					format "b.wirecolor = color (random 0 255) (random 0 255) (random 0 255);" to:cmd
			)
		)
		else messagebox "Please select objects you wish to see in the preview." title:"No selection" beep:false
		return cmd as string
	)
	
	fn checkIfOnline =
	(
		socket = MAXclient "127.0.0.1" 7777
		result = socket.send "\n"
		if result then
		(
			lbl_status.text = "Status: Online!"
			pb_status.color = color 0 150 0
			connecting = false
			return True
		)
		else
			if connecting then
			(
				lbl_status.text = "Status: Connecting..."
				pb_status.color = yellow
				btn_begin.enabled = false
				return False
			)
			else
			(
				lbl_status.text = "Status: Offline..."
				pb_status.color = color 150 0 0
				return False
			)
	)
	
	fn closeSession =
	(
		socket = MAXclient "127.0.0.1" 7777
		socket.send "quitMax #noPrompt;"
		socket.send "quitMax #noPrompt;"
	)
	
	fn enableSessionButtons state = 
	(
		btn_begin.enabled = not state
		btn_render.enabled = state
	)
	
	fn setupViewportStyleOnFirstLaunch =
	(
		viewportStyle = buildViewportStyleScript()
		socket = MAXclient "127.0.0.1" 7777
		socket.send viewportStyle
	)
	
	fn waitForPort =
	(
		active = False
		sleepTime = 0.2
		counter = 0
		limit = 20.0
		while not active and counter < limit do
		(
			if not checkIfOnline() then
			(
				sleep sleepTime
				counter += sleepTime
				windows.processPostedMessages()
				enableSessionButtons false
			)
			else
			(
				active = True
				counter += limit
				enableSessionButtons true
				setupViewportStyleOnFirstLaunch()
			)
		)
	)
	
	on fastPreview open do
	(
		spn_from.value = animationRange.start
		spn_to.value = animationRange.end
		setFPSLable()
		if checkIfOnline() do
		(
			enableSessionButtons true
		)
	)
	on fastPreview close do
		closeSession()
	on fastPreview okToClose do
	(
		queryBox "End session? The sandbox 3ds Max scene will be closed." title:"End session?" beep:false
	)
	on btn_begin pressed do
	(
		server = includeLocation + "MAXServer.ms"
		shellLaunch (getdir #maxroot + "3dsmax.exe") ("-q -U MAXScript \"" + server + "\"")
		connecting = true
		waitForPort()
	)
	on btn_Render pressed do
	(
		setFPSLable()
		if (isFileUnlocked previewFile) then
		(
			preview = buildPreviewScript()
			if preview != "" do
			(
				cam = exportCameraAndBuildMergeScript()
				viewportStyle = buildViewportStyleScript()
				sceneObjects = buildSceneObjectsAsBoxesScript()
				clearScene = "delete objects;"
				if sceneObjects != "" do
				(
					command = clearScene + cam + viewportStyle + sceneObjects + preview
					script = writeStringToFileAndReturnCommand command
					socket = MAXclient "127.0.0.1" 7777
					socket.send script
					socket.send script -- command is not sent on first attempt? Need to investigate
					ckeckIfBusy()
				)
			)
		)
		else messagebox "         The preview file is currently in use!" title:"Write failed!" beep:false
	)
	on chk_range changed state do
	(
		spn_from.enabled = state
		spn_to.enabled = state
	)
)

createdialog fastPreview



