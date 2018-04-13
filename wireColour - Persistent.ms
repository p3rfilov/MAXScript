/*---------------------------------------------------------------
Name: Persistent Wireframe Colour

Description:
Randomizes wireframe colour by object material. Stores 
wirecolour/material information within the file, so after each 
scene revision (additional geometry, new materials, etc.) the
wireframe colours are kept the same. This allows to reuse any
colour-based masks produced in a post-production package.

Author: Andrej Perfilov [perfilov3d.com]
Date: 13-04-2018
*/---------------------------------------------------------------

try(destroyDialog persistentWire)catch()
rollout persistentWire "Persistent Wirecolour" width:192 height:184
(
	button 'btn_wire' "Apply Wire Colour by Material" pos:[8,8] width:176 height:40 align:#left
	progressBar 'pb1' "ProgressBar" pos:[8,120] width:176 height:8 color:green align:#left
	label 'lbl1' "Scene Materials:" pos:[8,80] width:88 height:16 align:#left
	label 'lbl2' "Stored Materials:" pos:[8,96] width:88 height:16 align:#left
	button 'btn_cancel' "Cancel" pos:[8,48] width:176 height:24 enabled:false align:#left
	label 'lbl_sceneMats' "-" pos:[96,80] width:88 height:16 align:#left
	label 'lbl_storedMats' "-" pos:[96,96] width:88 height:16 align:#left
	button 'btn_del' "Delete wire colour data!" pos:[8,160] width:176 height:16 align:#left
	button 'btn_purge' "Purge Unused Materials" pos:[8,136] width:176 height:16 align:#left
	
	local stopped = False

	fn collectSceneMaterials =
	(
		sceneMats = #()
		sceneMats = for m in sceneMaterials where superClassOf m == material collect m
		return sceneMats
	)

	fn randomColour =
	(
		col = (color (random 0 255) (random 0 255) (random 0 255))
		return col
	)

	fn hasWireProp =
	(
		isProperty rootNode "wireData"
	)

	fn addWireDataAttribute =
	(
		if not hasWireProp() do
		(
			CA = attributes wireData
			(
				parameters params
				(
					materials type:#materialTab tabSizeVariable:true
					colours type:#colorTab tabSizeVariable:true
				)
			)
			custAttributes.add rootNode CA
		)
	)

	fn getStoredMaterials =
	(
		mat = #()
		if hasWireProp() do
			mat =  rootNode.wireData.materials as array
		return mat
	)

	fn getstoredCols =
	(
		col = #()
		if hasWireProp() do
			col = rootNode.wireData.colours as array
		return col
	)

	fn storeMaterials mats =
	(
		if hasWireProp() do
			rootNode.wireData.materials = mats
	)

	fn storeColours cols =
	(
		if hasWireProp() do
			rootNode.wireData.colours = cols
	)

	fn buttons state =
	(
		btn_wire.enabled = state
		btn_del.enabled = state
		btn_purge.enabled = state
		btn_cancel.enabled = not state
	)
	
	fn applyWireColour =
	(
		buttons off
		stopped = False
		addWireDataAttribute()
		sceneMats = collectSceneMaterials()
		storedMats = getStoredMaterials()
		storedCols = getstoredCols()
		count = sceneMats.count
		i = 0
		for mat in sceneMats where not stopped do
		(
			index = findItem storedMats mat
			if index == 0 then
			(
				col = randomColour()
				append storedMats mat
				append storedCols col
				for o in (refs.Dependents mat) where superClassOf (classof o) == node do
					try(o.wirecolor = col)catch()
			)
			else
			(
				col = storedCols[index]
				for o in (refs.Dependents mat) where superClassOf (classof o) == node do
					try(o.wirecolor = col)catch()
			)
			i += 1
			windows.processPostedMessages()
			pb1.value = 100*i/count
		)
		storeMaterials storedMats
		storeColours storedCols
		lbl_sceneMats.text = sceneMats.count as string
		lbl_storedMats.text = storedMats.count as string
		pb1.value = 0
		buttons on
	)
	
	fn forceSceneMaterialUpdate =
	(
		try
		(
			temp = GetDir #temp + "/forceSceneMaterialUpdate.max"
			saveNodes #() temp
			deleteFile temp
		)catch()
	)
	
	fn purgeUnusedMaterials =
	(
		buttons off
		forceSceneMaterialUpdate()
		sceneMats = collectSceneMaterials()
		storedMats = getStoredMaterials()
		storedCols = getstoredCols()
		count = storedMats.count
		for i = count to 1 by - 1 where not stopped do
		(
			deps = refs.Dependents storedMats[i]
			nodes = #()
			nodes = for o in deps where superClassOf (classof o) == node collect o
			if nodes.count == 0 do
			(
				deleteItem storedMats i
				deleteItem storedCols i
			)
			windows.processPostedMessages()
			pb1.value = 100*i/count
		)
		storeMaterials storedMats
		storeColours storedCols
		storedMats = getStoredMaterials()
		lbl_sceneMats.text = sceneMats.count as string
		lbl_storedMats.text = storedMats.count as string
		pb1.value = 0
		buttons on
	)
	
	on persistentWire open do
	(
		addWireDataAttribute()
		storedMats = getStoredMaterials()
		sceneMats = collectSceneMaterials()
		lbl_sceneMats.text = sceneMats.count as string
		lbl_storedMats.text = storedMats.count as string
	)
	on btn_wire pressed do
	(
		applyWireColour()
	)
	on btn_cancel pressed do
	(
		stopped = True
	)
	on btn_del pressed do
	(
		Yeap = queryBox "Delete Wire Colour data?" title:"Sure?" beep:false
		if (Yeap != undefined) and Yeap do
		(
			rnCount = rootnode.custAttributes.count
			for i = rnCount to 1 by -1 do
			try
			(
				attr = custAttributes.getdef rootnode i
				if attr.name == #wireData do
				(
					custAttributes.delete rootnode attr
					format ("Wire Colour data deleted!\n")
				)
			)
			catch()
			storedMats = getStoredMaterials()
			lbl_storedMats.text = storedMats.count as string
		)
	)
	on btn_purge pressed  do
	(
		purgeUnusedMaterials()
	)
)

createDialog persistentWire

