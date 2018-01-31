rollout unwrapRollout "Unwrap" width:176 height:472
(
	GroupBox 'grp1' "Flatten Unwrap" pos:[8,8] width:160 height:240 align:#left
	spinner 'spn_angleThr' "" pos:[112,32] width:48 height:16 range:[1,360,45] scale:1 align:#left
	label 'lbl1' "Angle threshold" pos:[16,32] width:88 height:16 align:#left
	label 'lbl3' "Spacing" pos:[16,48] width:88 height:16 align:#left
	spinner 'spn_spacing' "" pos:[112,48] width:48 height:16 range:[0,1,0.01] align:#left
	checkbox 'chk_normClusts' "Normalize Clusters" pos:[16,88] width:144 height:16 checked:true align:#left
	checkbox 'chk_rotClusts' "Rotate Clusters" pos:[16,104] width:144 height:16 checked:true align:#left
	checkbox 'chk_fillHoles' "Fill Holes" pos:[16,120] width:144 height:16 checked:true align:#left
	button 'btn_run' "Unwrap" pos:[16,328] width:144 height:40 align:#left
	button 'btn_stop' "Stop" pos:[16,368] width:144 height:16 enabled:false align:#left
	progressBar 'pb1' "ProgressBar" pos:[8,456] width:160 height:8 color:(color 0 255 0) align:#left
	checkbox 'chk_ignoreProxy' "Ignore V-Ray Proxies" pos:[16,228] width:144 height:16 checked:true align:#left
	checkbox 'chk_selectionOnly' "Run on Selection Only" pos:[16,272] width:144 height:16 checked:true align:#left
	button 'btn_removeUnwrap' "Remove autoUnwrap" pos:[16,296] width:144 height:24 align:#left
	spinner 'spn_channel' "" pos:[112,64] width:48 height:16 range:[1,99,5] type:#integer scale:1 align:#left
	label 'lbl12' "Map Channel" pos:[16,64] width:88 height:16 align:#left
	GroupBox 'grp7' "Actions" pos:[8,256] width:160 height:136 align:#left
	radiobuttons 'rdo_largeMesh' "" pos:[24,184] width:133 height:32 labels:#("Quick Unwrap", "Skip (add selection set)") default:2 align:#left
	spinner 'spn_verts' "" pos:[24,162] width:80 height:16 range:[1,1e+06,30000] type:#integer scale:1000 align:#left
	label 'lbl20' "vertices" pos:[108,162] width:40 height:16 align:#left
	GroupBox 'grp20' "Meshes larger than" pos:[16,144] width:144 height:80 align:#left
	listbox 'lbx_stats' "" pos:[8,400] width:160 height:4 readOnly:true align:#left

	local stopped = False
	local unwrapName = "autoUnwrap"
	
	fn buttons state =
	(
		btn_stop.enabled = not state
		btn_run.enabled = state
		btn_removeUnwrap.enabled = state
	)
	
	fn auto_Unwrap obj quick:false =
	(
		if not hasModifier obj unwrapName do
		(
			unwrapMod = Unwrap_UVW name:unwrapName
			addModifier obj unwrapMod
			objMod = obj.modifiers[unwrapName]
			objMod.selectPolygons #{}
			objMod.setMapChannel spn_channel.value
			if not quick then
			(
				objMod.setFlattenAngle spn_angleThr.value
				objMod.setFlattenSpacing spn_spacing.value
				objMod.setFlattenNormalize chk_normClusts.checked
				objMod.setFlattenRotate chk_rotClusts.checked
				objMod.setFlattenFillHoles chk_fillHoles.checked
				objMod.setMax5Flatten false
				objMod.flattenMapNoParams()
			)
			else
			(
				normList = 	#([0.57735,0.57735,-0.57735], \
								[-0.57735,-0.57735,-0.57735], \
								[-0.57735,0.57735,0.57735], \
								[0.57735,-0.57735,0.57735], \
								[-0.57735,0.57735,-0.57735], \
								[0.57735,0.57735,0.57735], \
								[0.57735,-0.57735,-0.57735], \
								[-0.57735,-0.57735,0.57735])
				objMod.normalMap 	normList spn_spacing.value \
											chk_normClusts.checked 6 chk_rotClusts.checked chk_fillHoles.checked
	-- 			objMod.pack 0 spn_spacing.value true true true
			)
			subobjectLevel = 0
		)
	)
	
	on unwrapRollout open do
	(
		stats = statsUpdater lbx_stats pb1
		stats.updateNow idle:true
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
		index = 0
		for obj in objs where not stopped do
		(
			stats.timeStart()
			if classOf obj == VrayProxy do obj.display = 4 -- show original mesh
			select obj
			
			if isMeshTooBig obj spn_verts.value then
			(
				if rdo_largeMesh.state == 1 then noUpdate (auto_Unwrap obj quick:true) -- diamond normal unwrap
				if rdo_largeMesh.state == 2 do append skippedObjs obj
			)
			else noUpdate (auto_Unwrap obj)
			
			stats.timeEnd()
			stats.updateNow obj:obj
			
			index += 1
			if (mod index 5) == 0.0 do gc() -- perform gc every 5 iterations
		)
		
		if skippedObjs.count > 0 then
			selectionSets["Large Meshes"] = skippedObjs
		else
			try(deleteItem selectionsets selectionSets["Large Meshes"])catch()
		
		if hadSelection then select objs else clearselection()
		buttons on
		stats.updateNow idle:true
	)
	on btn_stop pressed do
	(
		stopped = True
	)
	on btn_removeUnwrap pressed do
	(
		objs = getObjects chk_selectionOnly chk_ignoreProxy
		noUpdate (removeModifier objs unwrapName)
		gc()
	)
)