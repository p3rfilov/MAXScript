rollout optimizeRollout "Optimize Geometry" width:176 height:424
(
	button 'btn_removeOptimize' "Remove autoOptimize" pos:[16,248] width:144 height:24 align:#left
	checkbox 'chk_convertMesh' "Convert objects to Mesh" pos:[16,88] width:144 height:16 checked:true align:#left
	spinner 'spn_verts' "" pos:[88,32] width:72 height:16 range:[3,1e+06,30000] type:#integer scale:500 align:#left
	label 'lbl9' "Vertex count" pos:[16,32] width:64 height:16 align:#left
	GroupBox 'grp25' "Options" pos:[8,8] width:160 height:120 align:#left
	checkbox 'chk_ignoreProxy' "Ignore V-Ray Proxies" pos:[16,104] width:144 height:16 checked:true align:#left
	button 'btn_run' "Optimize" pos:[16,280] width:144 height:40 align:#left
	button 'btn_stop' "Stop" pos:[16,320] width:144 height:16 enabled:false align:#left
	progressBar 'pb1' "ProgressBar" pos:[8,408] width:160 height:8 color:(color 0 255 0) align:#left
	GroupBox 'grp7' "Actions" pos:[8,136] width:160 height:208 align:#left
	checkbox 'chk_selectionOnly' "Run on Selection Only" pos:[16,152] width:144 height:16 checked:true align:#left
	listbox 'lbx_stats' "" pos:[8,352] width:160 height:4 readOnly:true align:#left
	button 'btn_selectLargeMeshes' "Select Large Meshes" pos:[16,176] width:144 height:24 align:#left
	checkbox 'chk_skipOptimized' "Skip Optimized" pos:[16,56] width:144 height:16 enabled:true checked:true align:#left
	checkbox 'chk_centerPivot' "Center Object's Pivot" pos:[16,72] width:144 height:16 checked:true align:#left
	button 'btn_selectSmallMeshes' "Select Small Meshes" pos:[16,200] width:144 height:24 align:#left
	spinner 'spn_boxSize' "" pos:[88,224] width:72 height:16 range:[0.1,1e+06,50] type:#float scale:1 align:#left
	label 'lbl3' "Bbox size <" pos:[16,224] width:64 height:16 align:#left
	
	local stopped = False
	local optimizerName = "autoOptimize"
	
	fn buttons state =
	(
		btn_stop.enabled = not state
		btn_run.enabled = state
		btn_removeOptimize.enabled = state
		btn_selectLargeMeshes.enabled = state
		btn_selectSmallMeshes.enabled = state
	)
	
	fn auto_Optimize obj =
	(
		try(obj.modifiers[optimizerName].enabled = false)catch()
		if isMeshTooBig obj spn_verts.value do
		(
			select obj
			if not hasModifier obj optimizerName do
			(
				optimizerMod = ProOptimizer name:optimizerName
				addModifier obj optimizerMod
				optimizerMod.KeepUV = true
			)
			percent = ( (spn_verts.value as float) / (obj.mesh.numVerts as float) ) * 100.0
			optimizerMod = obj.modifiers[optimizerName]
			optimizerMod.enabled = true
			optimizerMod.VertexPercent = percent
			if not optimizerMod.Calculate do optimizerMod.Calculate = true
		)
	)
	
	fn checkValidCalculation obj =
	(
		if hasModifier obj optimizerName do
		(
			optimizerMod = obj.modifiers[optimizerName]
			if not optimizerMod.Calculate do optimizerMod.Calculate = true
		)
	)
	
	on optimizeRollout open do
	(
		stats = statsUpdater lbx_stats pb1
		stats.updateNow idle:true
	)
	on btn_removeOptimize pressed do
	(
		objs = getObjects chk_selectionOnly chk_ignoreProxy
		noUpdate (removeModifier objs optimizerName)
		gc()
	)
	on btn_run pressed do
	(
		stopped = False
		max modify mode
		buttons off
		hadSelection = selection.count > 0
		objs = getObjects chk_selectionOnly chk_ignoreProxy
		skippedObjs = #()
		
		stats = statsUpdater lbx_stats pb1 count:objs.count
		
		for obj in objs where not stopped do
		(
			stats.timeStart()
			if chk_convertMesh.checked and not hasModifier obj optimizerName do
			(
				addModifier obj (edit_Mesh())
				maxOps.CollapseNodeTo obj 1 true
				meshop.deleteIsoVerts obj
			)
			if chk_centerPivot.checked do obj.pivot = obj.center
			if classOf obj == VrayProxy do obj.display = 4 -- show whole mesh
			if not (hasModifier obj optimizerName and chk_skipOptimized.checked) do
			(
				noUpdate (auto_Optimize obj)
			)
			
			stats.timeEnd()
			stats.updateNow obj:obj
		)
		
		stats.resetCounter()
		for obj in objs where not stopped do
		(
			stats.timeStart()
			noUpdate (checkValidCalculation obj)
			stats.timeEnd()
			stats.updateNow obj:obj
		)
		
		if hadSelection then select objs else clearselection()
		buttons on
		stats.updateNow idle:true
	)
	on btn_stop pressed do
	(
		stopped = True
	)
	on btn_selectLargeMeshes pressed do
	(
		stopped = False
		buttons off
		sel = #()
		objs = getObjects chk_selectionOnly chk_ignoreProxy
		count = objs.count
		index = 0
		clearselection()
		for o in objs where not stopped do
		(
			if isMeshTooBig o spn_verts.value do append sel o
			index += 1
			pb1.value = 100*index/count
			windows.processPostedMessages()
		)
		select sel
		buttons on
		pb1.value = 0
	)
	on btn_selectSmallMeshes pressed do
	(
		stopped = False
		buttons off
		sel = #()
		objs = getObjects chk_selectionOnly chk_ignoreProxy
		count = objs.count
		index = 0
		clearselection()
		for o in objs where not stopped do
		(
			if isMeshTooSmall o spn_boxSize.value do
			(
				if isGroupMember o do setGroupOpen o.parent true
				append sel o
			)
			index += 1
			pb1.value = 100*index/count
			windows.processPostedMessages()
		)
		select sel
		buttons on
		pb1.value = 0
	)
)
