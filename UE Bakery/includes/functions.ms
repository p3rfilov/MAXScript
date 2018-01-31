-------------------------------------------- FUNCTIONS --------------------------------------------

struct statsUpdater
(
	public
	list_box = undefined,
	progress_bar = undefined,
	count = 0,
	index = 0,
	start = 0,
	end = 0,
	timeLeft = "unknown",
	fn timeStart = (start += timeStamp()),
	fn timeEnd = (end += timeStamp()),
	fn resetCounter =
	(
		index = 0
		start = 0
		end = 0
	),
	fn calculateTime =
	(
		index += 1
		t = (end/index - start/index) * (count - index) / 1000.0
		m = t / 60.0
		s = (m - (m as integer)) * 60
		timeLeft = ((m as integer) as string) + "m " + ((s as integer) as string) + "s"
		progress_bar.value = 100*index/count
	),
	fn updateNow obj:object idle:false =
	(
		stats = #()
		if not idle then
		(
			calculateTime()
			append stats ("Object: " + obj.name)
			append stats ("Vertex count: " + obj.mesh.numVerts as string)
			append stats ""
			append stats ("Est. time left: " + timeLeft)
			list_box.items = stats
		)
		else
		(
			append stats "Ready..."
			list_box.items = stats
			progress_bar.value = 0
		)
		windows.processPostedMessages()
	)
)

fn noUpdate func =
(
	undo off
	with redraw off
	(
		suspendediting()
		func
		resumeediting()
		windows.processPostedMessages()
	)
)

fn isMeshTooBig obj vertCount =
(
	m = snapshotAsMesh obj
	v = m.numVerts
	if v > vertCount then return True
	else return False
)

fn isMeshTooSmall obj bbSize =
(
	bb = nodeLocalBoundingBox obj
	size = distance obj.max obj.min
	if size < bbSize then return True
	else return False
)

fn hasModifier obj modName =
(
	if obj.modifiers[modName] != undefined then
		return True
	else return False
)

fn getObjects chk_selectionOnly chk_ignoreProxy =
(
	if chk_selectionOnly.checked then
	objs = selection
	else
	objs = objects
	geometryOnly = 	for obj in objs where \
							classOf obj == VrayProxy and not chk_ignoreProxy.checked or \
							canConvertTo obj Editable_Mesh or \
							superClassOf obj == shape and o.render_renderable \
							collect obj
	return geometryOnly
)

fn removeModifier objs modName =
(
	for o in objs do
	(
		if hasModifier o modName do
			deleteModifier o o.modifiers[modName]
	)
)

fn launchScript str =
(
	loc = getFilenamePath (getThisScriptFilename()) + "\\tools\\"
	try (fileIn (loc + str)) catch(messageBox (str + " Not found!"))
)


