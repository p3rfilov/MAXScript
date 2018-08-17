
----------------------------------------- WORK IN PROGRESS -----------------------------------------

try(destroydialog terrainExtractor)catch()

rollout terrainExtractor "Terrain Extractor" width:208 height:376
(
	edittext 'edt_dwgFile' "" pos:[13,32] width:179 height:16 readOnly:true align:#left
	GroupBox 'grp1' "Source File" pos:[8,8] width:192 height:104 align:#left
	button 'btn_browseDWG' "Select DWG File" pos:[16,56] width:176 height:24 align:#left
	GroupBox 'grp2' "Terrain Generation Parameters" pos:[8,192] width:192 height:176 align:#left
	button 'btn_genPoints' "Generate Points" pos:[16,144] width:96 height:32 align:#left
	dropdownList 'ddl_units' "" pos:[120,152] width:72 height:21 items:#("millimeters", "centimeters", "meters", "kilometers") selection:3 align:#left
	label 'lbl2' "Level units:" pos:[120,136] width:72 height:16 align:#left
	label 'lbl3' "SVG File Status:" pos:[16,88] width:80 height:16 align:#left
	label 'lbl_svgStatus' "Not Loaded" pos:[100,88] width:92 height:16 align:#left
	button 'btn_genTerrain' "Generate Terrain" pos:[16,216] width:176 height:32 align:#left
	label 'lbl4' "Terrain Resolution" pos:[40,256] width:96 height:16 align:#left
	spinner 'spn_resolution' "" pos:[136,256] width:56 height:16 range:[1,10000,50] type:#integer scale:1 align:#left
	spinner 'spn_expand' "" pos:[136,296] width:56 height:16 range:[1,20,1] type:#integer scale:1 align:#left
	label 'lbl13' "Footprint Expansion" pos:[35,296] width:96 height:16 align:#left
	spinner 'spn_relaxA' "" pos:[136,312] width:56 height:16 range:[0,1000,500] type:#integer scale:1 align:#left
	label 'lbl14' "Primary Smoothing" pos:[42,312] width:89 height:16 align:#left
	spinner 'spn_relaxB' "" pos:[136,328] width:56 height:16 range:[0,1000,0] type:#integer scale:1 align:#left
	label 'lbl15' "Secondary Smoothing" pos:[26,328] width:104 height:16 align:#left
	checkbox 'chk_optimize' "Optimize Topology" pos:[25,272] width:104 height:16 checked:false align:#left
	checkbox 'chk_refine' "Retain original altitudes" pos:[24,346] width:170 height:16 checked:true align:#left
	spinner 'spn_optBias' "" pos:[136,272] width:56 height:16 range:[0,1,0.1] type:#float scale:0.1 align:#left
	GroupBox 'grp5' "Point Generation" pos:[8,120] width:192 height:64 align:#left
	
	local DraftSight = "C:\\Program Files\\Dassault Systemes\\DraftSight\\bin\\DraftSight.exe"
	local dwgNode
	local svgData
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
		-- import dwg as One Object and disable Unit Scaling
		ini = getdir #plugcfg + @"\dwg_dxf_import.ini"
		setINISetting ini "LastUsedSettings" "CombineScenarioID" "5"
		setINISetting ini "LastUsedSettings" "ConvertUnits" "OFF"
		
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
	
	fn getLevelPointScaleFactor =
	(
		fileUnits = units.MetricType
		pointUnits = ddl_units.selected
		print fileUnits
		print pointUnits
		default = 1000 --scene units in mm; incoming units in m
		if fileUnits == #millimeters do
		(
			if pointUnits == "millimeters" do return 1
			if pointUnits == "centimeters" do return 10
			if pointUnits == "meters" do return 1000
			if pointUnits == "kilometers" do return 1000000
		)
		return default
	)
	
	fn generatePointCloud =
	(
		points = #()
		append points (createPoint [0,0,0] corner:true)
		
		scaleFactor = getScaleFactor svgData dwgNode
		height = svgData[1][2][1] * scaleFactor
		width = svgData[1][2][2] * scaleFactor
		append points (createPoint [width, height, 0] corner:true)
		
		for data in svgData[2] do
		(
			pos = [data[1][1]*scaleFactor, data[1][2]*scaleFactor, data[2]*getLevelPointScaleFactor()]
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
		
		if points.count > 0 do
		(
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
				elevatedCopy = #{}
				flat = #{}
				elevatedVertPositions = #()
				numVerts = getNumVerts terrMesh
				struct elevationPoint (pnt, pos)
				
				if chk_optimize.checked do
				(
					flatVerts = #{}
					for vert = 1 to numVerts do
					(
						vertPos = polyop.getVert terrMesh vert
						if vertPos.z == 0 do
						(
							append flatVerts vert
						)
					)
					select terrMesh
					polyop.setVertSelection terrMesh flatVerts
					setselectionlevel terrMesh #vertex
					modPanel.addModToSelection (Optimize bias1:spn_optBias.value) ui:on
					convertToPoly terrMesh
					numVerts = getNumVerts terrMesh
				)
				
				for vert = 1 to numVerts do
				(
					vertPos = polyop.getVert terrMesh vert
					if vertPos.z != 0 then
					(
						append elevated vert
						append elevatedVertPositions (elevationPoint pnt:vert pos:vertPos)
					)
					else
						append flat vert
				)
				
				elevatedCopy = copy elevated
				clearSelection()
				select terrMesh
				subobjectlevel = 1
				for v in elevatedCopy do
				(
					polyop.setVertSelection terrMesh #{v}
					for i = 1 to spn_expand.value do terrMesh.EditablePoly.GrowSelection()
					sel = (polyop.getVertSelection terrMesh) - elevatedCopy
					polyop.setVertSelection terrMesh sel
					newPos = polyop.getVert terrMesh v
					polyop.moveVert terrMesh sel [0, 0, newPos.z]
					elevatedCopy += sel
					flat -= sel
				)
				
				polyop.setVertSelection terrMesh (flat - elevated)
				setselectionlevel terrMesh #vertex
				modPanel.addModToSelection (Relax iterations:spn_relaxA.value) ui:on
				poly = Edit_Poly()
				modPanel.addModToSelection poly ui:on
				modPanel.addModToSelection (Relax iterations:spn_relaxB.value) ui:on
				
				convertToPoly terrMesh
				if chk_refine.checked do
					for v in elevatedVertPositions do
					(
						vertPos = polyop.getVert terrMesh v.pnt
						polyop.setVert terrMesh #{v.pnt} [vertPos.x, vertPos.y, v.pos.z]
					)
				clearSelection()
			)
			update terrMesh
		)
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
				lbl_svgStatus.text = "Point data Loaded!"
			)
		)
	)
	on btn_genPoints pressed do
	(
		if dwgNode != undefined and svgData != undefined then
			generatePointCloud()
		else
			messagebox "No point data found! Import DWG and Ggenerate SVG data first." title:"No data" beep:false
	)
	on btn_genTerrain pressed do
	(
		generateTerrain()
	)
)

createdialog terrainExtractor






