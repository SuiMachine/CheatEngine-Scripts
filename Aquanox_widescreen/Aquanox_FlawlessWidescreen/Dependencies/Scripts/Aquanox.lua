require(GlobalDependencys:GetDependency("StandardBase"):GetPackageName())

--GAME VARS
fAdditionalFOV = 0

--ControlVars
bFixEnabled = false
bMenuFix = false
bAspectRatio = false;
bEnableFOVhack = false;

--PROCESS VARS
Process_FriendlyName = Module:GetFriendlyName()
Process_WindowName = "*"
Process_ClassName = "*"
Process_EXEName = "Aqua.exe"

--INJECTION BEHAVIOUR
InjectDelay = 12000
WriteInterval = 100
SearchInterval = 250
SuspendThread = false

--Name                         Manual/Auto/Hybrid  		Steam/Origin/Any                IncludeFile:Configure;Enable;Periodic;Disable;
SupportedVersions = { 		
{"Automatically Detect",       "Hybrid",  			"Any",	                         "Configure_SignatureScan;Enable_Inject;Periodic;Disable_Inject;"},
}

function Init_Controls()
DefaultControls.AddFixToggle("MenuFix_Enable","Menu Scaling Fix","MenuScalingFix_Changed",25,60,180,14)
DefaultControls.AddFixToggle("AspectRatioFix_Enable","Aspect Ratio Fix","AspectRatioFix_Changed",25,79,180,14)
DefaultControls.AddFixToggle("FOVHack_Enable","Enable FOV hack","FOVHackEnable_Changed",25,98,180,14)
DefaultControls.AddHeader("Header_FOV","Camera FOV adjustment",245,70,210,17)
DefaultControls.AddFOVSlider("FOVSlider","FOVSlider_Changed",290,100,125,35)	
	
end


function Configure_SignatureScan() 

	if HackTool:GetArchitecture() == 32 then
	
		local tAddress = HackTool:AddAddress("MenuScale", 0x125950)
			HackTool:GetBaseAddress()
		print( tAddress:GetInfo(TYPE_ADDRESS) )
		
		local tAddress = HackTool:AddAddress("MenuFontFix", 0x1257B4)
			HackTool:GetBaseAddress()
		print( tAddress:GetInfo(TYPE_ADDRESS) )	
		
		local tAddress = HackTool:AddAddress("FOVFixAdr", 0x149CB1)
			HackTool:GetBaseAddress()
		print( tAddress:GetInfo(TYPE_ADDRESS) )	
		
		local tAddress = HackTool:AddAddress("AspectRatioAdr", 0x44874)
			HackTool:GetBaseAddress()
		print( tAddress:GetInfo(TYPE_ADDRESS) )	
		
		local tAddress = HackTool:AddAddress("SomeRefAdr", 0x26D100)
			HackTool:GetBaseAddress()
		print( tAddress:GetInfo(TYPE_ADDRESS) )
		
	end
	return true
end

function Enable_Inject() 


	local Variables = HackTool:AllocateMemory("Variables",0)
	Variables:PushFloat("VAR_FOVMultiplier")
	Variables:PushFloat("VAR_MenuFixMult")
	Variables:PushFloat("VAR_AspectRatioMult")
	Variables:Allocate()	

	
	ResolutionChanged()

	local asm = [[	
	
			(codecave:jmp)MenuScale,MenuScalingFix_cc:
				fld dword ptr[esi+0x14]
				fdiv dword ptr[(allocation)Variables->VAR_MenuFixMult]
				fmul dword ptr [eax]
				jmp %returnaddress%
				%end%
				
			(codecave:jmp)MenuFontFix,MenuFontScalingFix_cc:
				fmul dword ptr [esi+0x14]
				fdiv dword ptr[(allocation)Variables->VAR_MenuFixMult]
				fld dword ptr [esi+0x18]
				jmp %returnaddress%
				%end%		
				
			(codecave:jmp)AspectRatioAdr,AspectRatio_cc:
				repe movsd
				push edi
				sub edi,0xC
				movd xmm0,[edi]
				movd xmm1,[(allocation)Variables->VAR_AspectRatioMult]
				mulss xmm0,xmm1
				movd [edi],xmm0
				pop edi
				mov ecx,[(address)SomeRefAdr]
				jmp %returnaddress%
				%end%
				
			(codecave:jmp)FOVFixAdr,FOVHack_cc:
				movd xmm0,eax
				movd xmm1,[(allocation)Variables->VAR_FOVMultiplier]
				mulss xmm0,xmm1
				movd eax,xmm0
				mov [ecx+0x0C],eax
				mov [ecx+0x10],edx
				jmp %returnaddress%
				%end%				
	]]	

	
	if HackTool:CompileAssembly(asm,"MenuScale") == nil then
		return ErrorOccurred("Assembly compilation failed...")
	else
		Toggle_CodeCave("MenuScalingFix_cc",bMenuFix)
		Toggle_CodeCave("MenuFontScalingFix_cc",bMenuFix)
		Toggle_CodeCave("AspectRatio_cc",bAspectRatio)
		Toggle_CodeCave("FOVHack_cc",bEnableFOVhack)
	end	
		
end

function Periodic()
	local Variables = HackTool:GetAllocation("Variables")
	if Variables and bMenuFix == true then 								
		PluginViewport:AppendStatusMessage( string.format("\r\n     (UIScaling) UI Multiplier=%.3f",Variables["VAR_MenuFixMult"]:ReadFloat()))		
	end

	if Variables and bEnableFOVhack then
		Variables["VAR_FOVMultiplier"]:WriteFloat(fAdditionalFOV)
	end	
	
	PluginViewport:AppendStatusMessage(	string.format("\r\n     Camera FOV+=%.3f",fAdditionalFOV) )		
end

function Disable_Inject()
	
	CleanUp()
	
end

function ResolutionChanged() 

	local Variables = HackTool:GetAllocation("Variables")
	if Variables and Variables["VAR_FOVMultiplier"] and Variables["VAR_MenuFixMult"] and Variables["VAR_AspectRatioMult"] then
		local tFOV_Multiplier = 1.0 * (DisplayInfo:GetAspectRatio() / 1.3333)
		local tMenuFixVal = DisplayInfo:GetAspectRatio() / 1.3333
		local t_AspectRatioVal = DisplayInfo:GetAspectRatio() / 1.3333
		Variables["VAR_FOVMultiplier"]:WriteFloat( tFOV_Multiplier )	
		Variables["VAR_MenuFixMult"]:WriteFloat( tMenuFixVal )	
		Variables["VAR_AspectRatioMult"]:WriteFloat( t_AspectRatioVal )	
	end	

end

function MenuScalingFix_Changed(Sender)

	bMenuFix = Toggle_CheckFix(Sender)
	Toggle_CodeCave("MenuScalingFix_cc",bMenuFix)
	Toggle_CodeCave("MenuFontScalingFix_cc",bMenuFix)
	
end

function AspectRatioFix_Changed(Sender)

	bAspectRatio = Toggle_CheckFix(Sender)
	Toggle_CodeCave("AspectRatio_cc",bAspectRatio)
	
end

function FOVHackEnable_Changed(Sender)

	bEnableFOVhack = Toggle_CheckFix(Sender)
	Toggle_CodeCave("FOVHack_cc",bEnableFOVhack)
	
end

function HK_IncreaseFOV()	
	FOVSlider:OffsetPosition(1)
end

function HK_DecreaseFOV()	
	FOVSlider:OffsetPosition(-1)
end

function FOVSlider_Changed(Sender)

	fAdditionalFOV = Sender:GetScaledFloat(200)+1;
	lblFOVSlider.Caption:SetCaption( string.format("Value: %.2f",fAdditionalFOV) )	
	fAdditionalFOV = fAdditionalFOV * (DisplayInfo:GetAspectRatio() / 1.3333)
	ForceUpdate()	
		
end



function Init()	
	Init_BaseControls()
	Init_Controls()
end

function DeInit()
	DisableFix()
end