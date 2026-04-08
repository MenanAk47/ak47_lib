Lib47.String = {}

Lib47.String.Trim = function(value)
    if not value then return nil end
    return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
end