return function(State, Services)
    local module = {}
    function module.process(gunModule)
        if State.NoSpreadEnabled and type(gunModule) == "table" then
            pcall(function()
                if gunModule.spread then
                    if type(gunModule.spread) == "table" then
                        gunModule.spread.Min = 0
                        gunModule.spread.Max = 0
                    else
                        gunModule.spread = 0
                    end
                end
                if gunModule.bloom then
                    if type(gunModule.bloom) == "table" then
                        gunModule.bloom.angle = 0
                    else
                        gunModule.bloom = { angle = 0 }
                    end
                else
                    gunModule.bloom = { angle = 0 }
                end
            end)
        end
    end
    return module
end
