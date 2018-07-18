fn buildSceneObjectsAsBoxesScript =
(
	cmd = stringstream ""
	if selection.count != 0 then
	(
		sel = execute "$/selection/*"
		for obj in sel do
		(
			worldSpaceXform = obj.transform
			objectSpaceXform = inverse worldSpaceXform
			scaleX = obj.scale.x
			scaleY = obj.scale.y
			scaleZ = obj.scale.z
			obj.transform *= objectSpaceXform
			L = (obj.max.x - obj.min.x) * scaleX
			W = (obj.max.y - obj.min.y) * scaleY
			H = (obj.max.z - obj.min.z) * scaleZ
			obj.transform = worldSpaceXform
			b = box length:L width:W height:H
			b.transform = translate (obj.transform.rotation as matrix3) b.transform.pos
			r = b.transform.rotation * (inverse obj.transform.rotation)
			b.rotation *= r
			b.pos = obj.pos
			b.pos.z = obj.min.z
		)
	)
	else messagebox "Please select objects you wish to see in the preview." title:"No selection" beeb:false
	return cmd as string
)

buildSceneObjectsAsBoxesScript()