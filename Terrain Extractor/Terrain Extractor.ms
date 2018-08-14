
----------------------------------------- WORK IN PROGRESS -----------------------------------------

try(destroydialog terrainExtractor)catch()

rollout terrainExtractor "Terrain Extractor" width:248 height:304
(
	edittext 'edt_dwgFile' "" pos:[13,32] width:219 height:16 readOnly:true align:#left
	GroupBox 'grp1' "Source File" pos:[8,8] width:232 height:104 align:#left
	button 'btn_browseDWG' "Select DWG File" pos:[16,56] width:216 height:24 align:#left
	GroupBox 'grp2' "Terrain Generation Parameters" pos:[8,120] width:232 height:176 align:#left
	button 'btn_genPoints' "Generate Point Cloud" pos:[16,192] width:216 height:32 align:#left
	dropdownList 'ddl_units' "" pos:[48,144] width:64 height:21 items:#("millimeters", "centimeters", "meters", "kilometers") selection:3 align:#left
	label 'lbl2' "Units" pos:[16,146] width:32 height:16 align:#left
	label 'lbl3' "SVG File Status:" pos:[16,88] width:80 height:16 align:#left
	label 'lbl_svgStatus' "Not Loaded" pos:[104,88] width:128 height:16 align:#left
	button 'btn_genTerrain' "Generate Terrain" pos:[16,232] width:216 height:32 align:#left
	label 'lbl4' "Terrain Resolution" pos:[80,272] width:96 height:16 align:#left
	spinner 'spn_resolution' "" pos:[176,272] width:56 height:16 range:[1,10000,50] type:#integer scale:1 align:#left
	
	local DraftSight = "C:\\Program Files\\Dassault Systemes\\DraftSight\\bin\\DraftSight.exe"
	local dwgNode
	local svgData
	local scaleFactor
	local pointNames = "TerrExtPoint_"
	local cornerPointNames = "TerrExtCornerPoint_"
	local terrainName = "TerrExtTerrain_"
	
	/*---------------------------------------------------------------
	Purpose: Does stuff
	Input: None
	Return: None
	*/---------------------------------------------------------------
	fn FIND source str =
	(
		if (findString source str) != undefined then
			return true
		else
			return false
	)

	/*---------------------------------------------------------------
	Purpose: Does stuff
	Input: None
	Return: None
	*/---------------------------------------------------------------
	fn extractDataFromSVG file =
	(
		dims = #()
		levels = #()
		SVG = openFile file mode:"r"
		while not eof SVG do
		(
			levelPoint = #()
			coords = #()
			completeString = ""
			
			data = readline SVG
			if FIND data "<svg width=" do
			(
				d = filterString data "<svg width=\" height=\" \""
				-- filter out "mm"
				x = (filterString d[1] "mm")[1] as float 
				y = (filterString d[2] "mm")[1] as float
				append dims #(x, y)
			)
			if FIND data "viewBox=" do
			(
				d = filterString data "viewBox=\" \""
				append dims #(d[3] as float, d[4] as float) -- last 2 element
			)
			if FIND data "<g fill=" do
			(
				mat = filterString data "transform=\"matrix( )\""
				c = filterString (mat[mat.count]) ","
				if c.count > 1 do
				(
					coords = #(c[c.count] as float, c[c.count-1] as float)
				)
				append levelPoint coords
				for i = 1 to 4 do skipToNextLine SVG -- skip 4 lines
				data = readline SVG
				if FIND data "<text fill=" do
				(
					data = readline SVG
					while FIND data "</text>" do
					(
						s = filterString data " > </text>"
						if s[1] != "" and s[1] != undefined do
							completeString += s[1]
						for i = 1 to 2 do skipToNextLine SVG -- skip 2 lines
						data = readline SVG
					)
				)
			)
			if completeString != "" do
			(
				filteredStr = (filterString completeString "+")[1] -- filter out "+" sign
				if filteredStr != undefined and (filteredStr as float) != undefined do
				(
					append levelPoint (filteredStr as float)
					append levels levelPoint
				)
			)
		)
		close svg
		return #(dims, levels)
	)

	/*---------------------------------------------------------------
	Purpose: Does stuff
	Input: None
	Return: None
	*/---------------------------------------------------------------
	fn createScript script dwg svg =
	(
		result = createFile script
		close result
		if result != undefined then
		(
			f = openFile script mode:"w"
			format "Open %\n" dwg to:f
			format "ZoomFit\n" to:f
			format "Redraw\n" to:f
			format "ExportSVG %\n" svg to:f
			format "SaveAs %\n" (getdir #temp + @"\temp.dwg") to:f
			format "Quit" to:f
			close f
			return True
		)
		else
		(
			messagebox "       Could not write script!" title:"Write error!" beep:false
			return ""
		)
	)

	/*---------------------------------------------------------------
	Purpose: Does stuff
	Input: None
	Return: None
	*/---------------------------------------------------------------
	fn generateSVG dwg =
	(
		root = getFilenamePath dwg
		scriptFile = root + @"SaveAsSVG.scr"
		batFile = root + @"SaveAsSVG.bat"
		svgFile = root + @"\" + (getFilenameFile dwg) + ".svg"
		
		if (createScript scriptFile dwg svgFile) do
		(
			if (doesFileExist DraftSight ignoreCache:true) then
			(
				-- create Batch file
				result = createFile batFile
				close result
				if result != undefined then
				(
					f = openFile batFile mode:"w"
					format "\"%\" /b \"%\"" DraftSight scriptFile to:f
					close f
					DosCommand ("\"" + batFile + "\"")
					deleteFile batFile
				)
				else
					messagebox "       Could not create batch file!" title:"Write error!" beep:false
				deleteFile scriptFile
				return svgFile
			)
			else
			(
				messagebox "       Please make sure DraftSight is installed!" title:"Can't find DraftSight" beep:false
				return ""
			)
		)
	)

	/*---------------------------------------------------------------
	Purpose: imports dwg files and renames any nodes with the same name
	Input: dwg file path
	Return: imported node
	*/---------------------------------------------------------------
	fn importDwg dwg =
	(
		-- import dwg as One Object
		ini = getdir #plugcfg + @"\dwg_dxf_import.ini"
		setINISetting ini "LastUsedSettings" "CombineScenarioID" "5"
		
		-- make sure we don't have any duplicate names before importing
		dwgName = getFilenameFile dwg
		for i in objects where i.name == dwgName do i.name = uniquename (dwgName+"_") numDigits:3
			
		importFile dwg #noPrompt
		return getNodeByName dwgName
	)

	fn getScaleFactor svgData dwgNode =
	(
		dwgHeight = abs(dwgNode.max.y - dwgNode.min.y)
		dims = svgData[1]
		svgHeight = dims[1][2] / dims[1][1] * dims[2][1]
		scaleFactor = dwgHeight / svgHeight
		return scaleFactor
	)
	
	fn createPoint pos corner:false =
	(
		p = point pos:pos size:5.0 constantscreensize:true
		if not corner then
			p.name = uniquename pointNames numDigits:4
		else
			p.name = uniquename cornerPointNames numDigits:2
		return p
	)
	
	fn generatePointCloud =
	(
		points = #()
		append points (createPoint [0,0,0] corner:true)
		
		height = svgData[1][2][1] * scaleFactor
		width = svgData[1][2][2] * scaleFactor
		append points (createPoint [width, height, 0] corner:true)
		
		for data in svgData[2] do
		(
			pos = [data[1][1]*scaleFactor, data[1][2]*scaleFactor, data[2]*1000]
			append points (createPoint pos)
		)
		
		group points name:"Terrain Point Cloud"
		parent = points[1].parent
		rotate parent (angleaxis -90 [0,0,1])
		centerPivot parent
		parent.pivot.z = 0
		parent.pos = dwgNode.pos
	)
	
	fn generateTerrain =
	(
		points = for i in helpers where (matchPattern i.name pattern:(pointNames + "*")) collect i
-- 		positions = #()
-- 		for i in points do
-- 		(
-- 			append positions i.pos.x
-- 			append positions i.pos.y
-- 			append positions i.pos.z
-- 		)
-- 		terrMesh = mesh mesh:(nvpx.CreateConvexFromPoints positions points.count 1.0)
			
-- 		height = abs(dwgNode.max.y - dwgNode.min.y)
-- 		width = abs(dwgNode.max.x - dwgNode.min.x)
			
		height = abs(points[1].parent.max.y - points[1].parent.min.y)
		width = abs(points[1].parent.max.x - points[1].parent.min.x)
			
		heightRes = spn_resolution.value
		if width > height then
			widthRes = (width / height * spn_resolution.value) as integer
		else
			widthRes = (height / width * spn_resolution.value) as integer
		
		terrMesh = plane length:height width:width pos:points[1].parent.pos name:(uniquename terrainName numDigits:3)
		terrMesh.lengthsegs = heightRes
		terrMesh.widthsegs = widthRes
		
		convertToMesh terrMesh
		undo off
		(
			for p in points do
			(
				r = ray p.pos [0, 0, -p.pos.z]
				hit = intersectRayEx terrMesh r
				if hit != undefined do
				(
					meshop.divideFace terrMesh hit[2] barycoord:hit[3]
					vert = getNumVerts terrMesh
					vertPos = getVert terrMesh vert
					setVert terrMesh vert [vertPos.x, vertPos.y, p.pos.z]
				)
			)
			
			convertToPoly terrMesh
			elevated = #{}
			flat = #{}
			verts = getNumVerts terrMesh
			for vert = 1 to verts do
			(
				vertPos = polyop.getVert terrMesh vert
				if vertPos.z != 0 then
					append elevated vert
				else
					append flat vert
			)
			update terrMesh
			select terrMesh
			subobjectlevel = 1
			for v in elevated do
			(
				polyop.setVertSelection terrMesh #{v}
				terrMesh.EditablePoly.GrowSelection()
				sel = (polyop.getVertSelection terrMesh) - elevated
				polyop.setVertSelection terrMesh sel
				newPos = polyop.getVert terrMesh v
				polyop.moveVert terrMesh sel [0, 0, newPos.z]
				elevated += sel
			)
			subobjectlevel = 0
			clearSelection()
			
-- 			verts = getNumVerts terrMesh
-- 			for v = 1 to verts do
-- 			(
-- 				vertPos = getVert terrMesh v
-- 				if vertPos.z == 0 do setVert terrMesh v [vertPos.x, vertPos.y, points[1].parent.max.z]
-- 			)
		)
		update terrMesh
	)
	
	on btn_browseDWG pressed do
	(
		f = getOpenFileName types:"DWG(*.dwg)|*.dwg"
		if f != undefined do
		(
			edt_dwgFile.text = f
			dwgNode = importDwg f
			centerPivot dwgNode
			dwgNode.pivot.z = 0
			svgFile = generateSVG f
			if svgFile != "" do
			(
				svgData = extractDataFromSVG svgFile
				scaleFactor = getScaleFactor svgData dwgNode
			)
		)
	)
	on btn_genPoints pressed do
	(
		generatePointCloud()
	)
	on btn_genTerrain pressed do
	(
		generateTerrain()
	)
)

createdialog terrainExtractor






