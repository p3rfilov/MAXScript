rollout sceneCleanRollout "Scene Cleanup" width:176 height:72
(
	button 'btn_linkComp' "Remove LinkComposites" pos:[8,8] width:160 height:24 align:#left
	button 'btn_attach' "Attach by Proximity" pos:[8,40] width:160 height:24 align:#left
	
	on btn_linkComp pressed  do
	(
		launchScript "LinkComposite Cleaner.ms"
	)
	on btn_attach pressed  do
	(
		launchScript "Attach by Proximity.ms"
	)
)