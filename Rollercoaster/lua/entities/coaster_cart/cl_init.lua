include( "shared.lua" )

ENT.OffDaRailz = false

ENT.Mass = 80

ENT.Velocity = 10 //Starting velocity
ENT.Multiplier = 1 //Multiplier to set the same speed per node segment
ENT.Controller = nil //Controller entity. Useless
ENT.CoastSound = nil //Sound of just moving
ENT.ChainSound = nil //Sound of chains (Move to serverside?)
ENT.WindSound  = nil //Sound of wind
ENT.ShakeMultiplier = 1 //Multiplier to fine-tune shaking
ENT.Timer = math.huge

ENT.RenderGroup 	= RENDERGROUP_TRANSLUCENT

//Create the sounds
function ENT:Initialize()
	self.CoastSound = CreateSound( self, "coaster_ride.wav" )
	self.CoastSound:PlayEx(0.5, 100)

	self.WindSound = CreateSound( self, "coaster_wind.wav")
	self.WindSound:PlayEx(0, 100)
	
	self.ChainSound = CreateSound( self, "coaster_chain.wav" )

	local sequence = self:LookupSequence( "idle" )
	self:ResetSequence( sequence )
	self:SetPlaybackRate( 1.0 )

	if self:GetModel() == "models/sunabouzu/sonic_the_carthog.mdl" then
		surface.PlaySound("coaster_sonic_the_carthog.mp3")
		self.Timer = CurTime() + 24.00
		self.Enabled = true

		local sequence = self:LookupSequence( "GOING_FAST" )
		self:ResetSequence( sequence )
		self:SetPlaybackRate( 1.0 )
	end
end

function ENT:Draw()
	if self.Enabled then
		if !self.Frame then self.Frame = 0 end

		self.Frame = self.Frame + ( FrameTime() * self:GetVelocity():Length() / 300 )
		self:FrameAdvance( self.Frame )
		self:SetCycle( self.Frame )
	end
	self:DrawModel()	

end

function ENT:Think()
	if self.Enabled then
		if !self.Frame then self.Frame = 0 end
		
		self.Frame = self.Frame + ( FrameTime() * self:GetVelocity():Length() / 300 )
		self:FrameAdvance( self.Frame )
		self:SetCycle( self.Frame )
	end


	local CurrentNode = self:GetCurrentNode()
	if IsValid( CurrentNode ) && CurrentNode:EntIndex() != 1 && CurrentNode.GetType && CurrentNode:GetType() == COASTER_NODE_CHAINS then
		if self.ChainSound then
			if !self.ChainSound:IsPlaying() then
				self.ChainSound:PlayEx(1, 100)
			end
		else
			self.ChainSound = CreateSound( self, "coaster_chain.wav" )
		end
	else
		if self.ChainSound then
			if self.ChainSound:IsPlaying() then
				self.ChainSound:Stop()
			end
		end

		self.OffDaRailz = CurrentNode:EntIndex() == 1
	end

	if CurTime() >= self.Timer then
		CoasterBlur = 1.000
		self.ShakeMultiplier = 30
	end


	//Change sound pitch and volume depending on speed
	if self.OffDaRailz then
		if self.CoastSound != nil then self.CoastSound:Stop() end
	else
		if self.CoastSound != nil then
			if !self.CoastSound:IsPlaying() then
				self.CoastSound:PlayEx( 0.5, 100)
			end

			self.CoastSound:ChangePitch(math.Clamp( (self:GetVelocity():Length() / 8) , 1, 240 ) )
		else
			self.CoastSound = CreateSound( self, "coaster_ride.wav" )
		end

		if self.WindSound != nil then
			if !self.WindSound:IsPlaying() then
				self.WindSound:PlayEx(0, 100)
			end

			self.WindSound:ChangeVolume(math.Clamp( (self:GetVelocity():Length() / 1100) , 0, 1 ) )

			local pitch = 90 + (self:GetVelocity():Length() / 15)
			self.WindSound:ChangePitch(math.Clamp( pitch , 90, 120 ) )
		else
			self.WindSound = CreateSound( self, "coaster_wind.wav" )
		end

	end
	
	//I have no idea, I just threw these values in
	local amp = 0
	if LocalPlayer():InVehicle() then
		amp = math.Clamp( self:GetVelocity():Length() / 1000, 0, 32 )
		if amp < 0.15 then amp = 0 end //So we don't have a bunch of tiny rumbles
	else
		//amp = math.Clamp(  / 0.01, 0, 32 )
		amp = math.Clamp( self:GetVelocity():Length() / LocalPlayer():GetPos():Distance( self:GetPos() ) *0.1, 0, 2000 )
		if amp < 0.55 then amp = 0 end //So we don't have a bunch of tiny rumbles
	end
	amp = amp * self.ShakeMultiplier
	util.ScreenShake( LocalPlayer():GetPos(), amp, 300, 0.10, 300 )

end

//Remove sounds
function ENT:OnRemove()
	if self.CoastSound != nil then
		self.CoastSound:Stop()
		self.CoastSound = nil
	end
	
	if self.ChainSound != nil then
		self.ChainSound:Stop()
		self.ChainSound = nil
	end

	if self.WindSound != nil then
		self.WindSound:Stop()
		self.WindSound = nil
	end
end


//There isn't a way to equip a swep while in a vehicle
//And there isn't a way to hook into mouse pressing for none-HUD things
hook.Add("PlayerBindPress", "Coaster_cart_events", function( ply, bind, pressed )
	if !IsValid( ply ) || !ply:InVehicle() then return end

	local pod = ply:GetVehicle()
	if !IsValid( pod ) || !IsValid( pod:GetParent() ) || pod:GetParent():GetClass() != "coaster_cart" then return end

	if string.find(bind, "+attack2") then
		RunConsoleCommand("coaster_cart_click", "2")
	elseif string.find(bind, "+attack") then
		RunConsoleCommand("coaster_cart_click", "1")
	end
end )

