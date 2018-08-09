
----------------------------------------- WORK IN PROGRESS -----------------------------------------


svgFile = "//vr/c/Scripts/Andrej's Scripts/Terrain Extractor/Tests/EXTERNAL WORKS.svg"

try(destroydialog terrainExtractor)catch()

rollout terrainExtractor "Terrain Extractor" width:248 height:336
(
	edittext 'edt_dwgFile' "" pos:[13,32] width:219 height:16 align:#left
	GroupBox 'grp1' "Source File" pos:[8,8] width:232 height:80 align:#left
	button 'btn_browseDWG' "Select DWG File" pos:[128,56] width:104 height:24 align:#left
	GroupBox 'grp2' "Terrain Generation Parameters" pos:[8,96] width:232 height:112 align:#left
	button 'btn_generate' "Generate Terrain" pos:[16,168] width:216 height:32 enabled:false align:#left
	dropdownList 'ddl_units' "" pos:[56,56] width:64 height:21 items:#("millimeters", "centimeters", "meters", "kilometers") selection:3 align:#left
	label 'lbl2' "Units" pos:[20,59] width:32 height:16 align:#left
)

-- createdialog terrainExtractor

fn FIND source str =
(
	if (findString source str) != undefined then
		return true
	else
		return false
)

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
	
	for i in levels do print i
-- 	return #(dims, levels)
)

extractDataFromSVG svgFile

fn insertVertsAndMoveToAltiture mesh positions =
(
	--intersectRayEx
	--meshop.divideFace obj f barycoord:[0.1,0.1,0.5]
)




