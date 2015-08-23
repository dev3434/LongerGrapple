-- Longer Grapple by Dev_34
class 'cGrapple'

function cGrapple:__init()
	objectargs = {}
	objectargs.collision = "km02.towercomplex.flz/key013_01_lod1-g_col.pfx"
	objectargs.model = ""
	dowork = false
	interpolationtable = {}
	ticks = 75
	-- CONFIG --
	range = 1200 -- range of grappling hook (recommended: 85 - 1200)
	pointswitchdistance = 80 -- (distance from next point on line at which tracer object's position is transferred)
	firstpointdistance = 45 -- (distance from player at which the first point is roughly placed. recommended: 30 - 60. cannot be over 83.5)
	numpoints = 15 -- (roughly controls the number of point created, higher is less, lower is more. recommended: 5 - 25. affects smoothness of grappling)
	-- END CONFIG --
end

function cGrapple:InputManager(args)
ticks = ticks + 1
if ticks < 75 then return end -- prevent spam
	if args.input == Action.FireGrapple then
		ticks = 0
		ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, range + 1)
		if not ray.distance or not ray.position then return end
		if ray.distance > range or ray.distance < 83.5 then return end -- if unobstructed ray (no hit) and longer than normal
		local state = LocalPlayer:GetBaseState()
		if state ~= 6 and state ~= 12 and state ~= 19 and state ~= 7 and state ~= 9 then return end -- state limitation
		--
		if tracer == nil then
			objectargs.position = LocalPlayer:GetPosition() + (Camera:GetAngle() * (Vector3.Forward * 25))
			objectargs.angle = Angle()
			tracer = ClientStaticObject.Create(objectargs)
		end
		totalpoints = math.floor(ray.distance / numpoints)
		camangle = Camera:GetAngle()
		dowork = true
		timer = Timer()
		local closestpoint = totalpoints
		local closestdistance = math.huge
		local cpos = Camera:GetPosition()
		for i = 1, totalpoints do
			local pos = math.lerp(Camera:GetPosition(), ray.position, i/totalpoints) -- split line into points
			interpolationtable[i] = pos
			local dist = cpos:Distance(pos)
			if dist >= firstpointdistance and dist < closestdistance then -- select point as close to first point distance from player as possible
				closestdistance = dist
				closestpoint = Copy(i)
			end
		end
		point = Copy(closestpoint)
		absolutemaximum = interpolationtable[totalpoints] + (Camera:GetAngle() * Vector3.Forward * 1.5) -- move past surface
		tracer:SetPosition(interpolationtable[point] - (Camera:GetAngle() * Vector3.Up) + (Camera:GetAngle() * Vector3.Left)) -- adjust offset
		tracer:SetAngle(camangle)
		event = Events:Subscribe("PreTick", grap, grap.OnTick)
	end
end

function cGrapple:OnTick()
	if LocalPlayer:GetBaseState() ~= 208 then
		if timer then
			if timer:GetSeconds() > 2.0 then
				dowork = false
				for k,v in pairs(interpolationtable) do interpolationtable[k] = nil end
				timer = nil
				if IsValid(tracer) then
					tracer:Remove()
					tracer = nil
				end
				Events:Unsubscribe(event)
			end
		end
	end	
	if dowork == true then
		if IsValid(tracer) then
			if not timer then return end
			if timer:GetSeconds() < .75 then return end -- fire delay
			local campos = Camera:GetPosition()
			local nextpoint = point + 1
			if nextpoint == totalpoints + 1 then
				tracer:SetPosition(absolutemaximum - (Camera:GetAngle() * Vector3.Up) + (Camera:GetAngle() * Vector3.Left))
				tracer:SetAngle(camangle)
				dowork = false
				return
			end
			if campos:Distance(interpolationtable[nextpoint]) <= pointswitchdistance then -- configure switch point distance here
				point = point + 1
				tracer:SetPosition(interpolationtable[point] - (Camera:GetAngle() * Vector3.Up) + (Camera:GetAngle() * Vector3.Left))
				tracer:SetAngle(camangle)
			end
		end
	end
end

function cGrapple:OnUnload()
	if IsValid(tracer) then tracer:Remove() end
end

grap = cGrapple() -- class set-up only used for organization

Events:Subscribe("LocalPlayerInput", grap, grap.InputManager)
Events:Subscribe("ModuleUnload", grap, grap.OnUnload)