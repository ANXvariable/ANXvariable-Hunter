-- MyMod

local envy = mods["MGReturns-ENVY"]
envy.auto()
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()

PATH = _ENV["!plugins_mod_folder_path"]



-- ========== Main ==========

local function initialize()
    -- Initialization of content goes here
    -- https://github.com/RoRRModdingToolkit/RoRR_Modding_Toolkit/wiki/Initialize
    
end
Initialize(initialize)

-- ** Uncomment the two lines below to re-call initialize() on hotload **
-- if hotload then initialize() end
-- hotload = true


gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    -- This is an example of a hook
    -- This hook in particular will run every frame after it has finished loading (i.e., "Hopoo Games" appears)
    -- You can hook into any function in the game
    -- Use pre_script_hook instead to run code before the function
    -- https://github.com/return-of-modding/ReturnOfModding/blob/master/docs/lua/tables/gm.md
    
end)