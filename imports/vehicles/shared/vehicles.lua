Lib47.GetPlate = function(vehicle)
    if vehicle == 0 or vehicle == nil then return end
    return Lib47.String.Trim(GetVehicleNumberPlateText(vehicle))
end