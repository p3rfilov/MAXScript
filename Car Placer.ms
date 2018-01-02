/*----------------------------------------------------------------------------------------------
-- Car Placer v1.0 [13-12-2017] by Andrej Perfilov [perfilov3d.com]
-- Tested on Max 2017, Vray 3

Use:
Place and align your car models and their wheels to uneven surfaces
 
Options:
“Remove surface smoothing” – applies a smooth modifier and clears smoothing groups for more precise placement
“Precision Mode (slower)” – goes through mesh vertices to determine the bottom of the wheel. Otherwise uses bounding box
“Filter” – Is “wheel” by default. Used to determine which objects to align

*/----------------------------------------------------------------------------------------------

try(destroydialog carPlacer)catch()

rollout carPlacer "Car Placer v1.0" width:176 height:447
(
	pickbutton 'btn_base' "> Pick Base Surface <" pos:[8,208] width:160 height:24 align:#left
	checkbutton 'btn_start' "Start" pos:[8,256] width:160 height:40 align:#left
	edittext 'edt_find' text:"wheel" pos:[48,360] width:112 height:16 align:#left
	spinner 'spn_offset' "" pos:[104,384] width:56 height:16 range:[-1000,1000,-10] scale:5 align:#left
	label 'lbl1' "Surface offset" pos:[16,384] width:80 height:16 align:#left
	checkbox 'chk_precise' "Precision Mode (slower)" pos:[16,336] width:144 height:16 enabled:true checked:true align:#left
	listbox 'lbx_items' "Item List" pos:[8,8] width:160 height:10 align:#left
	checkbox 'chk_random' "Randomize Item selection" pos:[8,184] width:160 height:16 checked:true align:#left
	button 'btn_add' "+" pos:[8,160] width:80 height:24 align:#left
	button 'btn_del' "-" pos:[88,160] width:80 height:24 align:#left
	checkbox 'chk_smooth' "Remove surface smoothing" pos:[8,232] width:160 height:16 checked:false align:#left
	GroupBox 'grp1' "Wheel Settings" pos:[8,304] width:160 height:136 align:#left
	checkbox 'chk_wheels' "Align wheels" pos:[16,320] width:144 height:16 checked:true align:#left
	label 'lbl3' "Filter:" pos:[16,360] width:32 height:16 align:#left
	button 'btn_readjust' "Readjust Selected" pos:[16,408] width:144 height:24 align:#left
	--HyperLink 'hl' "perfilov3d.com" pos:[96,440] width:72 height:16 address:"http://perfilov3d.com/" align:#left
	
	local baseObj
	local wString
	local currItem
	local currInstance
	local instObjs
	local oldTransform
	local objPlaced = false
	local placePoint
	
	
	-- Purpose: Places objects on the surface of the base mesh
	-- Input: Base mesh object, array of objects to place, filter string, float offset value
	-- Return: None
	fn dropObjects base objs filt offset =
	(
		fn getRealMinZ theObj = -- thanks to Bobo at http://forums.cgsociety.org
		(
			theMinZ = pow 10 10
			theMesh = snapshotasmesh theObj
			for v = 1 to theMesh.numverts do
			(
				thePos = getVert theMesh v
				if thePos.z < theMinZ then theMinZ = thePos.z
			)
			delete theMesh
			return theMinZ
		)
		
		for i in objs where (matchPattern i.name pattern:("*" + filt + "*") ignoreCase:true) do
		(
			-- need to re-implement this using transform matrix later
			oldPos = i.pos
			in coordsys #local i.pos.z -= 100.0
			newPos = i.pos
			i.pos = oldPos
			target = normalize (newPos - oldPos)
			-- need to re-implement this using transform matrix later

			rayDown = Ray i.pos target
			newPos = intersectRay base rayDown
			if newPos != undefined then
			(
				if chk_precise.checked then
					min = getRealMinZ i
				else 
					min = ((nodeLocalBoundingBox i)[1]).z
				height = i.center.z - min
				dist = distance newPos.pos i.pos
				in coordsys #local i.pos.z -= dist - height - offset
			)--else try( print (i.name + ": No Intersection with " + baseObj.name) )catch()
		)
	)
	

	fn placeObj obj base =
	(
		r = intersectRay base (mapScreenToWorldRay mouse.pos)
		if r != undefined then
		(
			TM = matrixFromNormal r.dir
			TM.row4 = r.pos
			obj.transform = TM
			objPlaced = true
		)
		else objPlaced = false
	)
	
	tool carPaint
	(
		fn stopTheTool =
		(
			btn_start.checked = false
			#stop
		)
		
		on start do
		(
			instObjs = undefined
			if isValidNode baseObj then
			(
				if classOf baseObj != Editable_mesh do
				try
				(
					m = Edit_Mesh()
					m.name = "baseMesh"
					addModifier baseObj m
				)catch()
				if chk_smooth.checked do
				try
				(
					m = Smooth()
					m.name = "smoothBase"
					addModifier baseObj m
				)catch()
			)
			else
			(
				messagebox "Base Surface has been deleted!" title:"No Base Object" beep:false
				stopTheTool()
			)
			
			if lbx_items.items.count > 0 then
			(
				if chk_random.checked then
				(
					i = random 1 lbx_items.items.count
					currItem = getNodebyName lbx_items.items[i]
					if currItem == undefined do
					(
						lbx_items.items = deleteItem lbx_items.items i
						if lbx_items.items.count > 0 and lbx_items.selection > 0 then
						(
							i = random 1 lbx_items.items.count
							currItem = getNodebyName lbx_items.items[i]
						)
						else 
						(
							messagebox "Item List is empty!" title:"No Items" beep:false
							stopTheTool()
						)
					)
				)
				else
				(
					currItem = getNodebyName lbx_items.items[lbx_items.selection]
					if currItem == undefined do
					(
						lbx_items.items = deleteItem lbx_items.items i
						if lbx_items.items.count > 0 and lbx_items.selection > 0 then
						(
							currItem = getNodebyName lbx_items.items[lbx_items.selection]
						)
						else
						(
							messagebox "Item List is empty!" title:"No Items" beep:false
							stopTheTool()
						)
					)
				)
			)
			else
			(
				messagebox "Item List is empty!" title:"No Items" beep:false
				stopTheTool()
			)
		)
		
		on mousePoint clickno do
		(
			if isValidNode baseObj then
			(
				if clickno == 1 do
				(
					if instObjs != undefined do delete instObjs
					maxOps.cloneNodes currItem cloneType:#instance newNodes:&instObjs #nodialog
					for i in instObjs where i.parent == undefined do currInstance = i
					placeObj currInstance baseObj
				)
				if clickno == 2 do
				(
					placeObj currInstance baseObj
					oldTransform = currInstance.transform -- capture the transform to be used for rotation
					if not objPlaced do
					try
					(
						delete instObjs
						#stop
					)catch()
				)
				if clickno == 3 do
				(
					if chk_wheels.checked do
					try (dropObjects baseObj instObjs edt_find.text spn_offset.value) catch()
					#stop
				)
			)
			else
			(
				stopTheTool()
			)
		)
		
		on mouseMove clickno do
		(
			if isValidNode currInstance then
			(
				if clickno == 1 or clickno == 2 do
				(
					placeObj currInstance baseObj
					oldTransform = currInstance.transform -- capture the transform to be used for rotation
				)
				if clickno == 3 do
				(
					origin = currInstance.pos
					target = intersectRay baseObj (mapScreenToWorldRay mouse.pos)
					if target == undefined then
						target = (mapScreenToWorldRay mouse.pos).pos
					else
						target = target.pos
					target = [target.x, target.y, currInstance.pos.z]
					v = normalize (target - origin)
					theZ = [0,0,1]
					theX = normalize (cross theZ v)
					theY = normalize (cross theZ theX)
					TM = matrix3 theX theY theZ origin
					
					rot = (TM.rotationpart as eulerAngles).z
					currInstance.transform = (rotateZmatrix rot) * oldTransform
				)
			)
		)
		
		on mouseAbort clickno do
		(
			try(delete instObjs)catch()
			if clickno <= 1 do btn_start.checked = false
		)
		
		on stop do
		(
			if not objPlaced do
				try(delete instObjs)catch()
			instObjs = undefined
			if btn_start.checked do startTool carPaint
			try
			(
				for i = baseObj.modifiers.count to 1 by -1 do
				(
					if baseObj.modifiers[i].name == "baseMesh" do deleteModifier baseObj i
					if baseObj.modifiers[i].name == "smoothBase" do deleteModifier baseObj i
				)
			)catch()
		)
	)

	on btn_base picked obj do
	(
		btn_base.text = obj.name
		baseObj = obj
	)
	on btn_start changed state do
	(
		if state then
		(
			if baseObj != undefined then
			(
				wString = "*" + edt_find.text + "*"
				-- group undo to avoid crashing
				undo label:"Car Paint" on startTool carPaint
			)
			else
			(
				messagebox "Pick Base Surface first!" title:"No Base Object" beep:false
				btn_start.checked = false
			)
		)
		else
		(
			stopTool carPaint
		)
	)
	on lbx_items selected sel do
	(
		currItem = getNodebyName lbx_items.items[sel]
	)
	on btn_add pressed do
	(
		arr = lbx_items.items
		for obj in (execute "$/selection/*") do appendIfUnique arr obj.name
		lbx_items.items = arr
	)
	on btn_del pressed do
	(
		if lbx_items.items.count > 0 and lbx_items.selection > 0 do
		lbx_items.items = deleteItem lbx_items.items lbx_items.selection
	)
	on btn_readjust pressed do
	(
		if selection.count != 0 then
		(
			if baseObj != undefined then
			undo label:"Align Wheels" on
				try (dropObjects baseObj selection edt_find.text spn_offset.value) catch()
			else messagebox "Pick Base Surface first!" title:"No Base Object" beep:false
		)
		else messagebox "Make a selection first!" title:"Nothing Selected" beep:false
	)
)

createdialog carPlacer






