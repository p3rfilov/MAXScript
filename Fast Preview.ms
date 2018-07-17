---------------- WORK IN PROGRESS ----------------

/*---------------------------------------------------------------
Name: Fast Preview

Description:
This script renders animated previews in a sepparate 3ds Max session

Author: Andrej Perfilov [perfilov3d.com]
Date: 01-01-2018
*/---------------------------------------------------------------

includeLocation = getFilenamePath (getThisScriptFilename()) + "TCP\\"
filein (includeLocation + "MAXClient.ms")

try(destroydialog fastPreview)catch()

rollout fastPreview "Fast Preview" width:144 height:224
(
	button 'btn_begin' "Begin Session" pos:[8,40] width:128 height:40 align:#left
	progressBar 'pb_status' "" pos:[8,8] width:128 height:8 value:100 color:yellow align:#left
	button 'btn_render' "Render Preview" pos:[8,176] width:128 height:40 align:#left enabled:true
	checkbox 'chk_range' "Set custom range" pos:[16,105] width:104 height:16 checked:false align:#left
	GroupBox 'grp1' "Sequence Info" pos:[8,88] width:128 height:80 align:#left
	spinner 'spn_from' "" pos:[16,125] width:56 height:16 enabled:false range:[-100000,100000,0] type:#integer scale:1 align:#left
	spinner 'spn_to' "" pos:[72,124] width:56 height:16 enabled:false range:[-100000,100000,0] type:#integer scale:1 align:#left
	label 'lbl_status' "Status: " pos:[8,20] width:128 height:16 align:#left
	label 'lbl_fps' "@ ?? fps" pos:[47,147] width:52 height:16 align:#left
	
	local connecting = false
	local mergeFile = GetDir #temp + "/quickPreview.max"
	
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
			format "preview_name = (getDir #preview)+\"/quickpreview.avi\";" to:cmd
			format "view_size = getViewSize()/2;" to:cmd
			format "anim_bmp = bitmap view_size.x view_size.y filename:preview_name;" to:cmd
			format "for t = % to % do" range[1] range[2] to:cmd
			format "(" to:cmd
			format "sliderTime = t;" to:cmd
			format "dib = gw.getViewportDib();" to:cmd
			format "copy dib anim_bmp;" to:cmd
			format "save anim_bmp;" to:cmd
			format ");" to:cmd
			format "close anim_bmp;" to:cmd
			format "gc();" to:cmd
			format "shellLaunch preview_name \"\";" to:cmd
		)
		return cmd as string
	)
	
	fn exportCameraAndBuildMergeScript =
	(
		cam = getactivecamera()
		saveNodes #(cam) mergeFile
		cmd = stringstream ""
		format "mergemaxfile % quiet:true;" mergeFile to:cmd
		format "viewport.setCamera %;" cam to:cmd
		return cmd as string
	)
	
	fn buildViewportStyleScript =
	(
		cmd = stringstream ""
		format "viewport.setLayout #layout_1;" to:cmd
		format "viewport.setGridVisibility #all %;" (viewport.getGridVisibility 1) to:cmd
		format "viewport.SetRenderLevel %;" (viewport.GetRenderLevel()) to:cmd
		format "viewport.SetShowEdgeFaces %;" (viewport.GetShowEdgeFaces()) to:cmd
		format "viewport.SetTransparencyLevel %;" (viewport.GetTransparencyLevel()) to:cmd
		return cmd as string
	)
	
	fn buildSceneObjectsScript =
	(
		cmd = stringstream ""
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
		socket.send "quitMax #noPrompt"
-- 		socket.send "exit"
	)
	
	fn enableSessionButtons state = 
	(
		btn_begin.enabled = not state
		btn_render.enabled = state
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
			)
		)
	)
	
	on fastPreview open do
	(
		spn_from.value = animationRange.start
		spn_to.value = animationRange.end
		lbl_fps.text = "@ " + frameRate as string + " fps"
		if checkIfOnline() do
		(
			enableSessionButtons true
		)
	)
	on fastPreview okToClose do
	(
		queryBox "End session? The sandbox 3ds Max scene will be closed." title:"End session?" beep:false
	)
	on fastPreview close do closeSession()
	on btn_begin pressed do
	(
		server = includeLocation + "MAXServer.ms"
		shellLaunch (getdir #maxroot + "3dsmax.exe") (" -U MAXScript \"" + server + "\"")
		connecting = true
		waitForPort()
	)
	on btn_render pressed do
	(
		preview = buildPreviewScript()
		if previewScript != "" do
		(
			cam = exportCameraAndBuildMergeScript()
			viewportStyle = buildViewportStyleScript()
			sceneObjects = buildSceneObjectsScript()
			command = viewportStyle + cam + sceneObjects + preview
			execute command
		)
	)
	on chk_range changed state do
	(
		spn_from.enabled = state
		spn_to.enabled = state
	)
)

createdialog fastPreview



