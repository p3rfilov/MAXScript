/*----------------------------------------------------------------------------------------------
-- Attach by Proximity v1.0 [08-12-2017] by Andrej Perfilov [perfilov3d.com]
-- Tested on Max 2012-2017, Vray 2-3

Features:
- Attach objects based on their distance to each other
- Clean up nested groups
 
Options:
Distance threshold – distance in world units (mm). If an object is closer, it gets attached.
Split by material – takes object material into account
Preview (wire colour) – get a preview of how the geometry going to be attached. Splits all objects into same colour groups based on their distance
Clean Selected Groups – Clean up nested groups

*/----------------------------------------------------------------------------------------------

try(destroydialog PrAttach)catch()

rollout PrAttach "Attach by Proximity" width:192 height:328
(
	spinner 'spn_thr' "" pos:[112,8] width:72 height:16 range:[1,1e+06,300] type:#float scale:10 align:#left
	label 'lbl1' "Distance threshold" pos:[8,8] width:96 height:16 align:#left
	checkbox 'chk_minMax' "Use Bounding box (more precise)" pos:[8,32] width:176 height:16 enabled:true checked:true align:#left
	checkbox 'chk_mat' "Split by Material" pos:[8,48] width:176 height:16 checked:true align:#left
	button 'btn_attach' "Attach" pos:[8,136] width:176 height:24 align:#left
	button 'btn_cancel' "Cancel" pos:[8,200] width:176 height:24 enabled:false align:#left
	progressBar 'pb1' "ProgressBar" pos:[8,232] width:176 height:8 color:(color 0 128 0) align:#left
	button 'btn_preview' "Preview (wire color)" pos:[8,88] width:176 height:24 align:#left
	checkbox 'chk_disp' "Ignore VrayDisplacementMod" pos:[8,64] width:176 height:16 checked:true align:#left
	GroupBox 'grp1' "Additional Tools" pos:[8,248] width:176 height:72 align:#left
	button 'btn_groups' "Clean Selected Groups" pos:[16,264] width:160 height:24 align:#left
	checkbox 'chk_delVerts' "Delete Isolated Vertices" pos:[8,160] width:176 height:16 checked:true align:#left
	button 'btn_deadGeometry' "Select Dead Geometry" pos:[16,288] width:160 height:24 align:#left
	checkbox 'chk_select' "Select Attached on Completion" pos:[8,176] width:176 height:16 align:#left
	radioButtons 'rdo_dispColor' "" pos:[30,113] width:138 height:16 labels:#("material", "object") columns:2 align:#left
	
	local objArr = #()
	local returnArr = #()
	local objClouds = #()
	local cancel = False
	local cicleCount
	local objCount = 0
	local count
	local gcCount = 2000 -- recursions before doing a gc()
	
	fn buttons state =
	(
		btn_preview.enabled = state
		btn_attach.enabled = state
		btn_cancel.enabled = not state
		btn_groups.enabled = state
		btn_deadGeometry.enabled = state
	)
	
	fn deleteIsolatedVerts obj =
	(
		--maxOps.CollapseNodeTo obj 1 true
		try(if classOf obj == editable_mesh do meshop.deleteIsoVerts obj)catch()
		try(if classOf obj == editable_poly do obj.EditablePoly.deleteIsoVerts())catch()
	)
	
	fn deadGeometry pb1 =
	(
		buttons off
		sel = #()
		clearSelection()
		suspendEditing()
		count = 0
		cancel = false
		with redraw off
		(
			gCount = geometry.count
			for i in geometry where not i.isHidden do
			(
				if not cancel do
				(
					count += 1
					windows.processPostedMessages()
					pb1.value = 100*count/gCount
					if try(i.mesh.numVerts == 0)catch(false) do
					(
						if isGroupMember i do setGroupOpen i.parent true
						append sel i
					)
				)
			)
		)
		select sel
		
		pb1.value = 100
		windows.processPostedMessages()
		pb1.value = 0
		buttons on
		resumeEditing()
	)
	
	-- Thanks to https://gist.github.com/JokerMartini
	fn get_all_nodes nodes:#() =
	(
		allnodes = #()
		for n in nodes do
		(
			append allnodes n
			join allnodes (get_all_nodes nodes:(n.children))
		)
		allnodes
	)
	
	-- Purpose: Cleans nested groups
	-- Input: Selection
	-- Return: None
	fn cleanGroups =
	(
		if selection.count != 0 then
		(
			sel = execute "$/selection/*"
			selCount = sel.count
			count = 0
			cancel = False
			buttons off
			for obj in sel where not cancel do
			(
				children = get_all_nodes nodes:#(obj)
				for i in children where i != obj do
				(
					i.parent = obj
				)
				for i in children where i != obj do
				(
					if isGroupHead i and classof i == Dummy do delete i
				)
				count += 1
				pb1.value = 100*count/selCount
				windows.processPostedMessages()
			)
			pb1.value = 0
			buttons on
		)
		else messagebox "Make a selection first!" title:"No selection" beeb:false
	)
	
	
	/*---------------------------------------------------------------------------------------------------
	Purpose:
		Divides the selection into clusters of nearest neighbour objects
	Input: 
		- Array of objects (selection)
		- Temporary empty array (returnArr)
		- Empty array to be populated with data (objClouds)
		- Distance threshold in world units
		- minMax boolean. If set, nodeLocalBoundingBox min and max values are used to calculate proximity
	
	Return: Indirect
		Creates a 3-dimensional array (objClouds) of following structure:
		#( 
			#( 
				head node 1 , #( node1_1, node1_2, node1_3, ... )
			) , 
			#( 
				head node 2 , #( node2_1, node2_2, node2_3, ... )
			) 
		)
	*/---------------------------------------------------------------------------------------------------
	fn FindNNs objArr returnArr objClouds thr minMax:false =
	(
		undo off
		(
			with redraw off
			(
				while not cancel and objArr.count != 0 do
				(
					tempArr = #()
					if returnArr.count == 0 do -- if passed array is empty, pop and append one object
					(
						a = #()
						append a objArr[1]
						append returnArr a
						deleteitem objArr 1
					)
					thisArr = returnArr[returnArr.count]
					for j = thisArr.count to 1 by -1 do
					(
						pos = thisArr[j].pos
						for i = objArr.count to 1 by -1 do
						(
							cicleCount += 1
							distArr = #()
							append distArr (distance pos objArr[i].pos)
							if minMax do
							(
								bb = nodeLocalBoundingBox objArr[i]
								append distArr (distance pos bb[1])
								append distArr (distance pos bb[2])
							)
							if (amin distArr) <= thr do
							(
								append tempArr objArr[i]
								deleteItem objArr i
								count += 1
								pb1.value = 100*count/objCount
								windows.processPostedMessages()
							)
							--if (mod cicleCount gcCount) == 0.0 do gc light:true -- perform garbage collection
						)
					)
					if tempArr.count > 0 then
					(
						append returnArr tempArr
						if objArr.count == 0 do append objClouds returnArr -- we are DONE
					)
					else
					(
						append objClouds returnArr
						returnArr = #()
					)
				)
				pb1.value = 0
			)
		)
	)
	
	fn getObjects =
	(
		objCount = objArr.count
		count = 0
		cicleCount = 0
		returnArr = #()
		objClouds = #()
		if chk_mat.checked then
		(
			matArr = #()
			matObjArr = #()
			for i in objArr do
			(
				appendifunique matArr i.mat
			)
			for i in matArr do
			(
				a = #()
				for j in objArr do
				(
					if j.mat == i do append a j
				)
				append matObjArr a
			)
			for i in matObjArr where i.count > 1 do
			(
				returnArr = #()
				FindNNs i returnArr objClouds spn_thr.value minMax:chk_minMax.checked
			)
			--print ("Done in " + cicleCount as string + " cicles")
		)
		else FindNNs objArr returnArr objClouds spn_thr.value minMax:chk_minMax.checked
	)
	
	fn filterSelection =
	(
		objArr = #()
		buttons off
		for i in selection where superclassOf i == GeometryClass do
		(
			i.pivot = i.center
			if chk_disp.checked then
			(
				hit = 0
				for j in i.modifiers where hit == 0 do
				(
					if classof j == VRayDisplacementMod do hit += 1
				)
				if hit == 0 do append objArr i
			)
			else append objArr i
		)
	)
	
	fn flip_Normals obj =
	(
		if  (try(obj.scale.x < 0)catch(false)) or \
			(try(obj.scale.y < 0)catch(false)) or \
			(try(obj.scale.z < 0)catch(false)) do
			(
				n = Normalmodifier flip:true
				addmodifier obj n
				ResetScale obj
			)
	)
	
	on btn_attach pressed do
	(
		undo off
		(
			with redraw off
			(
				filterSelection()
				if objArr.count > 1 do
				(
					getObjects()
					Yeap = true
					Yeap = (queryBox "Attach selected? The Undo history will be cleared!" title:"Proceed?" beep:false)
					if Yeap do
					(
						clearselection()
						suspendEditing()
						cnt = 0
						for i in objClouds do -- objClouds
						(
							if i.count > 1 do -- if had no neighbours
							(
								head = i[1][1]
								if isGroupMember head do setGroupOpen head.parent true
								par = head.parent
								head.parent = undefined
								InstanceMgr.MakeObjectsUnique head #individual
								flip_Normals head
								resetxform head
								convertToMesh head
								for o = 2 to i.count do -- retArr
								(
									for j = i[o].count to 1 by -1 where not cancel do -- tempArr
									(
										ob = i[o][j]
										ob.parent = undefined
										InstanceMgr.MakeObjectsUnique ob #individual
										flip_Normals ob
										resetxform ob
										convertToMesh ob
										attach head ob
										cnt += 1
										pb1.value = 100*cnt/objCount
										windows.processPostedMessages()
									)
								)
								head.parent = par
								if chk_delVerts.checked do deleteIsolatedVerts head
								if chk_select.checked then selectmore head
								else
									if isGroupMember head do setGroupOpen head.parent false
							)
							gc() --light:true -- perform garbage collection
						)
						resumeEditing()
					)
				)
			)
		)
		buttons on
		objArr = #()
		returnArr = #()
		objClouds = #()
		pb1.value = 0
	)
	on btn_cancel pressed do
	(
		cancel = True
	)
	on btn_preview pressed do
	(
		undo off
		(
			with redraw off
			(
				filterSelection()
				if objArr.count > 1 do
				(
					getObjects()
					cnt = 0
					for i in objClouds do
					(
						c = [(random 0 255),(random 0 255),(random 0 255)]
						for o in i do
						(
							for j in o where not cancel do
							(
								j.wirecolor = c
								cnt += 1
								pb1.value = 100*cnt/objCount
								windows.processPostedMessages()
							)
						)
					)
					gc light:true -- perform garbage collection
				)
			)
		)
		
		rdo_dispColor.state = 2
		displayColor.shaded = #object
		
		buttons on
		objArr = #()
		returnArr = #()
		objClouds = #()
		pb1.value = 0
		--redrawViews()
	)
	on btn_groups pressed do
	(
		--undo label:"Clean Groups" on cleanGroups()
		undo off
			with redraw off
			(
				suspendEditing()
				cleanGroups()
				gc()
				resumeEditing()
			)
	)
	on btn_deadGeometry pressed do
	(
		deadGeometry pb1
	)
	on rdo_dispColor changed stat do
	(
		if stat == 1 do displayColor.shaded = #material
		if stat == 2 do displayColor.shaded = #object
	)
)

createdialog PrAttach






