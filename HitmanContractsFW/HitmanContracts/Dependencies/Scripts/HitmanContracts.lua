require(GlobalDependencys:GetDependency("StandardBase"):GetPackageName())

--GAME VARS
fAdditionalFOV = 0
fDefaultAspectRatio = 1.33333

--ControlVars
bFOVFix = true
bHelmetFOV = true
bFixEnabled = true
bHUDFix = true

--PROCESS VARS
Process_FriendlyName = Module:GetFriendlyName()
Process_WindowName = "*"
Process_ClassName = "*"
Process_EXEName = "HitmanContracts.exe"

--INJECTION BEHAVIOUR
InjectDelay = 2500
WriteInterval = 100
SearchInterval = 500
SuspendThread = true

--Name                         Manual/Auto/Hybrid  		Steam/Origin/Any                IncludeFile:Configure;Enable;Periodic;Disable;
SupportedVersions = { 		
{"Automatically Detect",       "Hybrid",  			  	"Steam",	                        "Configure_SignatureScan;Enable_Inject;Periodic;Disable_Inject;"},
}

function Init_Controls()
	DefaultControls.AddFixToggle("FOVHack_Enable","Enable FOV hack","FOVHackEnable_Changed",25,60,180,14)
end

function Configure_SignatureScan() 

	local tAddress = HackTool:AddAddress("FOVFixAdr", 0xC19E0);
	
	return true

end


function Enable_Inject() 

	local Variables = HackTool:AllocateMemory("Variables",0)
	Variables:Allocate()

	FOVCalculator1 = HackTool:InjectFOVCalculator("FOVCalculator1")
	
	ResolutionChanged()
	
	local asm = [[		
			
		(codecave:jmp)FOVFixAdr,FOVFix_cc:
			%originalcode%
			call (allocation)FOVCalculator1
			jmp %returnaddress%
			%end%	
	]]

	if HackTool:CompileAssembly(asm,"FOVFixs") == nil then
		return ErrorOccurred("Assembly compilation failed...")
	else
		Toggle_CodeCave("FOVFix_cc",bFOVFix)
	end	
		
end

function Disable_Inject()
	CleanUp()
end

function ResolutionChanged() 
	
	UpdateFOVCalculator("FOVCalculator1",DisplayInfo:GetAspectRatio()/fDefaultAspectRatio,fAdditionalFOV)

end


function FOVHackEnable_Changed(Sender)

	bEnableFOVhack = Toggle_CheckFix(Sender)
	Toggle_CodeCave("FOVFix_cc",bEnableFOVhack)
	
end

function Init()	
	Init_BaseControls()
	Init_Controls()
end

function DeInit()
	DisableFix()
end

