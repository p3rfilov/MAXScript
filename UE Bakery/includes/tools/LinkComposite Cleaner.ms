try(destroydialog remLinkComp)catch()

rollout remLinkComp "Remove LinkComposites" width:192 height:88
(
	button 'btn_clean' "Remove LinkComposites" pos:[8,8] width:176 height:32 align:#left
	button 'btn_stop' "Stop" pos:[8,40] width:176 height:24 enabled:false align:#left
	progressBar 'pb1' "ProgressBar" pos:[8,72] width:176 height:8 align:#left color:green
	
	local stopped = False
	
	fn butEnable state =
	(
		btn_stop.enabled = not state
		btn_clean.enabled = state
		pb1.value = 0
	)
	
	on btn_clean pressed do
	(
		with redraw off
		(
			suspendEditing()
			butEnable False
			stopped = False
			count = 0
			oCount = objects.count
			for o in objects where not stopped do
			(
				windows.processPostedMessages()
				count += 1
				pb1.value = 100*count/oCount
				if not o.ishidden do
				(
					o.controller=prs()
					if classof o.parent == LinkComposite do
					(
						o.parent = undefined
					)
				)
			)
			count = 0
			remCount = 0
			remArr = #()
			gCount = geometry.count
			for o in geometry where not stopped do
			(
				windows.processPostedMessages()
				count += 1
				pb1.value = 100*count/gCount
				if not o.ishidden and classof o == LinkComposite do
				(
					append remArr o
					remCount += 1
				)
			)
			delete remArr
			butEnable True
			resumeEditing()
			print (remCount as string + " LinkComposite's removed")
		)
	)
	on btn_stop pressed do
	(
		stopped = True
		butEnable True
	)
)
	
createdialog remLinkComp


