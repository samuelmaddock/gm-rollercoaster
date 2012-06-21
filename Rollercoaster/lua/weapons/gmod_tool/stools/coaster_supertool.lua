AddCSLuaFile( "weapons/gmod_tool/tab/tab_utils.lua")
AddCSLuaFile( "weapons/gmod_tool/tab/tabmanager.lua")
include("weapons/gmod_tool/tab/tabmanager.lua")
include("weapons/gmod_tool/tab/tab_utils.lua")

TOOL.Category   = "Rollercoaster"
TOOL.Name       = "Rollercoaster SuperTool"
TOOL.Command    = nil
TOOL.ConfigName	= nil

TOOL.ClientConVar["selected_tab"] = "1"

function TOOL:LeftClick(trace)
	local ply   = self:GetOwner()
	
	trace = {}
	trace.start  = ply:GetShootPos()
	trace.endpos = trace.start + (ply:GetAimVector() * 99999999)
	trace.filter = ply
	trace = util.TraceLine(trace)

	local class = self:GetCurrentTab()

	if class then
		return class:LeftClick(trace, self)
	end

end

function TOOL:RightClick(trace)
	local ply   = self:GetOwner()
	
	trace = {}
	trace.start  = ply:GetShootPos()
	trace.endpos = trace.start + (ply:GetAimVector() * 99999999)
	trace.filter = ply
	trace = util.TraceLine(trace)

	local class = self:GetCurrentTab()

	if class then
		return class:RightClick(trace, self)
	end
end

function TOOL:Reload(trace)
	local ply   = self:GetOwner()
	
	trace = {}
	trace.start  = ply:GetShootPos()
	trace.endpos = trace.start + (ply:GetAimVector() * 99999999)
	trace.filter = ply
	trace = util.TraceLine(trace)

	local class = self:GetCurrentTab()

	if class then
		return class:Reload(trace, self)
	end
end

function TOOL:Think()
	local class = self:GetCurrentTab()

	if CLIENT then
		local panel = controlpanel.Get("coaster_supertool")
		if panel.Tabs then
			local Sheet = panel.Tabs:GetActiveTab()

			if Sheet.Class && Sheet.Class != class then
				RunConsoleCommand("coaster_supertool_selected_tab", Sheet.Class.UniqueName )
				print("Setting current tab to " .. tostring( Sheet.Class.UniqueName ) )

			end
		end
	end

	// Class neccessary functions
	if self.CurrentClass != class then
		if self.CurrentClass then
			self.CurrentClass:Holster( self )
		end

		if class then
			class:Equip( self )

			//Update the header HUD
			if CLIENT then
				//print(class.Name)
				//language.remove("Tool_coaster_supertool_name")
				//language.Add( "Tool_coaster_supertool_name", class.Name )
				//language.Add( "Tool_coaster_supertool_desc", class.Description )
			end
		end

		self.CurrentClass = class
	end

	//Call their think function
	if class then
		return class:Think( self )
	end
end

function TOOL:Holster()
	local class = self:GetCurrentTab()

	if class then
		return class:Holster( self )
	end
end

function TOOL:GetCurrentTab()
	local Class = coastertabmanager.Get( self:GetClientInfo( "selected_tab") )

	if Class then
		return Class
	end
end

//Yoinked from garry's tool HUD rendering code.
function TOOL:DrawHUD()
	if ( !GetConVar("gmod_drawhelp"):GetBool() ) then return end
       
	local class = self:GetCurrentTab()
   
    local x, y = 50, 40
    local w, h = 0, 0
   
    local TextTable = {}
    local QuadTable = {}
   
    TextTable.font = "GModToolName"
    TextTable.color = Color( 240, 240, 240, 255 )
    TextTable.pos = { x, y }
    TextTable.text = class.Name or "None"
   
    w, h = draw.TextShadow( TextTable, 3 )
    y = y + h

    TextTable.font = "GModToolSubtitle"
    TextTable.pos = { x, y }
    TextTable.text = class.Description or "None"
    w, h = draw.TextShadow( TextTable, 2 )

    y = y + h + 11
   
    TextTable.font = "GModToolHelp"
    TextTable.pos = { x + 24, y  }
    TextTable.text = class.Instructions or "None"
    w, h = draw.TextShadow( TextTable, 2 )
end

local function DrawScrollingText( text, y, texwide )

	local w, h = surface.GetTextSize( text )
	w = w + 64

	local x = math.fmod( CurTime() * 400, w ) * -1;

	while ( x < texwide ) do

		surface.SetTextColor( 0, 0, 0, 255 )
		surface.SetTextPos( x + 3, y + 3 )
		surface.DrawText( text )
          
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.SetTextPos( x, y )
		surface.DrawText( text )
       
		x = x + w
           
	end
end

function TOOL:DrawToolScreen( TEX_SIZE )
	local class = self:GetCurrentTab()

	surface.SetFont("GModToolScreen")
	DrawScrollingText( class.Name or "None", 64, TEX_SIZE )
end



//THANKS ZAAAAAAK
function toSortedTable(T, mbr)
 local v, C, O
 C = {} O = {}
 repeat v = next(T, v) if v then C[v] = T[v] else break end until false

 while next(C, nil) do
  local low = 999999, low_v, x
  repeat x = next(C, x)
  if x and C[x][mbr] < low then low = C[x][mbr] low_v = x end 
  until x == nil

  table.insert(O, C[low_v]) C[low_v] = nil
 end
 return O
end


function TOOL.BuildCPanel(panel)	
	panel:AddControl( "Header", { Text = "#Tool_coaster_supertool_name", Description = "#Tool_coaster_supertool_desc" }  )

	local PropertySheet = vgui.Create( "DPropertySheet", panel )
	PropertySheet:SetPos( 5, 30 )
	PropertySheet:SetSize( 340, 600 )

	local FixedTable = toSortedTable( coastertabmanager.List, "Position")

	for k, v in pairs(FixedTable) do
		local panel = v:BuildPanel()
		RegisterTabPanel( panel, v.UniqueName )
		
		local sheet = PropertySheet:AddSheet( v.Name, panel, v.Icon, false, false, v.Description )	
		sheet.Tab.Class = v
	end

	panel:AddItem( PropertySheet )
	panel.Tabs = PropertySheet

end



if CLIENT then

	language.Add( "Tool_coaster_supertool_name", "" )
	language.Add( "Tool_coaster_supertool_desc", "" )
	language.Add( "Tool_coaster_supertool_0", "" )

end
