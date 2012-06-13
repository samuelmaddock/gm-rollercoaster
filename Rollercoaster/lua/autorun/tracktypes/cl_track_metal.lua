include("autorun/sh_enums.lua")
include( "autorun/mesh_beams.lua")

local TRACK = {}

TRACK.Name = "Metal Track"
TRACK.Description = "A nice metal coaster"
TRACK.Meshes = {}

local StrutOffset = 2 //Space between coaster struts
local Offset = 20  //Downwards offset of large center beam
local RailOffset = 25 //Distance track beams away from eachother
local Radius = 10 	//radius of the circular track beams
local PointCount = 7 //how many points make the cylinder of the track mesh

/******************************
Generate function. Generate the IMeshes.
******************************/
function TRACK:Generate( controller )
	if !IsValid( controller ) || !controller:IsController() then return end
	local Vertices = {} //Create an array that will hold an array of vertices (This is to split up the model)
	self.Meshes = {} 
	local modelCount = 1 

	Cylinder.Start( Radius, PointCount ) //We're starting up making a beam of cylinders
	local LastAng = nil
	for i = 1, #controller.CatmullRom.Spline do
		local NexterSegment = controller.Nodes[ controller:GetSplineSegment(i) + 2]
		local NextSegment = controller.Nodes[controller:GetSplineSegment(i) + 1]
		local ThisSegment = controller.Nodes[ controller:GetSplineSegment(i) ]

		local AngVec = Vector( 0, 0, 0 )
		local AngVec2 = Vector( 0, 0, 0 )

		if #controller.CatmullRom.Spline >= i + 1 then		
			AngVec = controller.CatmullRom.Spline[i] - controller.CatmullRom.Spline[i + 1]
			AngVec:Normalize()
		else
			AngVec = controller.CatmullRom.Spline[i] - controller.CatmullRom.PointsList[ #controller.CatmullRom.PointsList ]
			AngVec:Normalize()
		end

		if #controller.CatmullRom.Spline >= i + 2 then
			AngVec2 = controller.CatmullRom.Spline[i+1] - controller.CatmullRom.Spline[i+2]
			AngVec2:Normalize()
		else
			AngVec2 = AngVec

		end


		local ang = AngVec:Angle()
		local ang2 = AngVec2:Angle()
		if IsValid( ThisSegment ) && IsValid( NextSegment ) then
			//Get the percent along this node
			local perc = controller:PercAlongNode( i )

			local Roll = -Lerp( perc, ThisSegment:GetRoll(),NextSegment:GetRoll())	
			if ThisSegment:RelativeRoll() then
				Roll = Roll - ( ang.p - 180 )
			end
			ang:RotateAroundAxis( AngVec, Roll )

			//For shits and giggles get it for this one too
			local perc2 = controller:PercAlongNode( i + 1, true )
			local Roll2 = -Lerp( perc2, ThisSegment:GetRoll(), NextSegment:GetRoll() )
			if ThisSegment:RelativeRoll() then
				Roll2 = Roll2 - ( ang2.p - 180 )
			end
			ang2:RotateAroundAxis( AngVec2, Roll2 )
		end


		if #controller.CatmullRom.Spline >= i+1 then
			local posL = controller.CatmullRom.Spline[i] + ang:Right() * -RailOffset
			local posR = controller.CatmullRom.Spline[i] + ang:Right() * RailOffset
			local nPosL = controller.CatmullRom.Spline[i+1] + ang2:Right() * -RailOffset
			local nPosR = controller.CatmullRom.Spline[i+1] + ang2:Right() * RailOffset

			local vec = controller.CatmullRom.Spline[i] - controller.CatmullRom.Spline[i+1]

			local vec2 = vec

			if #controller.CatmullRom.Spline >= i+2 then
				vec2 = controller.CatmullRom.Spline[i+1] - controller.CatmullRom.Spline[i+2]
			end
			//vec:Normalize() //new
			NewAng = vec:Angle()
			NewAng:RotateAroundAxis( vec:Angle():Right(), 90 )
			NewAng:RotateAroundAxis( vec:Angle():Up(), 270 )

			if LastAng == nil then LastAng = NewAng end

			//vec:ANgle()
			Cylinder.AddBeam(controller.CatmullRom.Spline[i] + (ang:Up() * -Offset), LastAng, controller.CatmullRom.Spline[i+1] + (ang2:Up() * -Offset), NewAng, Radius )

			//Side rails
			Cylinder.AddBeam( posL, LastAng, nPosL, NewAng, 4 )
			Cylinder.AddBeam( posR, LastAng, nPosR, NewAng, 4 )

			if #Cylinder.Vertices > 50000 then// some arbitrary limit to split up the verts into seperate meshes

				Vertices[modelCount] = Cylinder.Vertices
				modelCount = modelCount + 1

				Cylinder.Vertices = {}
				Cylinder.TriCount = 1
			end
			LastAng = NewAng
		end
	end	

	local verts = Cylinder.EndBeam()
	Vertices[modelCount] = verts

	//Stage 2, create the struts in between the coaster rails
	local CurSegment = 2
	local Percent = 0
	local Multiplier = 1
	local StrutVerts = {} //mmm yeah strut those verts

	while CurSegment < #controller.CatmullRom.PointsList - 1 do
		local CurNode = controller.Nodes[CurSegment]
		local NextNode = controller.Nodes[CurSegment + 1]

		local Position = controller.CatmullRom:Point(CurSegment, Percent)

		local ang = controller:AngleAt(CurSegment, Percent)

		//Change the roll depending on the track
		local Roll = -Lerp( Percent, CurNode:GetRoll(), NextNode:GetRoll())	
		
		//Set the roll for the current track peice
		ang.r = Roll
		//ang:RotateAroundAxis( controller:AngleAt(CurSegment, Percent), Roll ) //BAM

		//Now... manage moving throughout the track evenly
		//Each spline has a certain multiplier so the cart travel at a constant speed throughout the track
		Multiplier = controller:GetMultiplier(CurSegment, Percent)

		//Move ourselves forward along the track
		Percent = Percent + ( Multiplier * StrutOffset )

		//Manage moving between nodes
		if Percent > 1 then
			CurSegment = CurSegment + 1
			if CurSegment > #controller.Nodes - 2 then 			
				break
			end	
			Percent = 0
		end
		local verts = controller:CreateStrutsMesh(Position, ang)
		table.Add( StrutVerts, verts ) //Combine the tables into da big table
	end

	//put the struts into the big vertices table
	if #Vertices > 0 then
		Vertices[#Vertices + 1] = StrutVerts
	end
	//controller.Verts = verts //Only stored for debugging

	for i=1, #Vertices do
		if #Vertices[i] > 2 then
			self.Meshes[i] = NewMesh()
			self.Meshes[i]:BuildFromTriangles( Vertices[i] )
		end
	end

	return true
end


/****************************
Draw function. Draw the mesh
****************************/
function TRACK:Draw( controller )
	if !IsValid( controller ) || !controller:IsController() then return end
	if !self.Meshes || #self.Meshes < 1 then return end

	for k, v in pairs( self.Meshes ) do
		//render.SetColorModulation( r / 255, g / 255, b / 255)
		if v then 
			v:Draw() //TODO: I think IMesh resets color modulation upon drawing. Figure out a way around this?
		end
		//render.SetColorModulation( 1, 1, 1)
	end
end

trackmanager.Register( EnumNames.Tracks[COASTER_TRACK_METAL], TRACK )