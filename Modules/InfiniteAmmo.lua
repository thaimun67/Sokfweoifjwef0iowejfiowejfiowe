return function(State, Services)
    local module = {}
    function module.process(self, gunModule)
        if State.InfiniteAmmoEnabled and type(gunModule) == "table" then
            if self.currentAmmo and self.currentAmmo <= 0 and gunModule.magSize then
                self.currentAmmo = gunModule.magSize
            end
            if self.currentAmmo then
                self.currentAmmo = self.currentAmmo + 1
            end
        end
    end
    return module
end
