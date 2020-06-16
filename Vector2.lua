Vector2 = {};

-- Arithmitic metamethods
local function add(self, value)
    return Vector2.Add(self, value);
end

local function sub(self, value)
    return Vector2.Subtract(self, value);
end

local function mul(self, value)
    return Vector2.Multiply(self, value);
end

local function div(self, value)
    return Vector2.Divide(self, value);
end

local function umn(self)
    return self * -1;
end

local function eq(self, value)
    return Vector2.Equals(self, value);
end

local function toString(self)
    return string.format("( %s, %s )", self.x, self.y);
end

-- Vector2 constructor
function Vector2.New(x, y)

    -- Error handling
    if x and type(x) ~= "number" then 
        error("number expected, got "..type(x))
    end

    if y and type(y) ~= "number" then 
        error("number expected, got "..type(y))
    end

    -- Sets up vector data structure
    local vectorData = setmetatable({
        className = "Vector2",
        x = x or 0,
        y = y or 0;
        }, Vector2
    );

    -- creates a metatable with all the metamethods to operate on vectors
    local vectorMethods = setmetatable({},{

        -- if there ever needs to be more indicies we can add funtionality here
        __index = function(self, index)
            return vectorData[index];
        end,

        __newindex = function(self, index, value)
            -- Check for valid index
            if index == "x" or index == "y" then

                -- If valid index check type
                if value and type(value) == "number" then
                    vectorData[index] = value;
                else
                    error("number expected, got "..type(index));
                end
            else
                error("Tried to index Vector2."..index..", invalid index.");
            end
        end,

        -- Setting the rest of the metamethods
        __add = add,
        __sub = sub,
        __mul = mul,
        __div = div,
        __unm = umn,
        __eq = eq,
		__tostring = toString
    });
    
    return vectorMethods;
end

-- Vector math with error handling
function Vector2.Add(vector, value)
    if vector.className and vector.className ~= "Vector2" then
        error("Invalid Vector2 object");
    else
        if type(value) == "number" then
            return Vector2.New(vector.x + value, vector.y + value);
        elseif type(value) == "table" then
            if value.className and value.className == "Vector2" then
                return Vector2.New(vector.x + value.x, vector.y + value.y);
            else
                error("attempt to perform arithmetic on " .. vector.className .. " and table");
            end
        else
            error("attempt to perform arithmetic on " .. vector.className .. " and " .. type(value));
        end
    end
end

function Vector2.Subtract(vector, value)
    if vector.className and vector.className ~= "Vector2" then
        error("Invalid Vector2 object");
    else
        if type(value) == "number" then
            return Vector2.New(vector.x - value, vector.y - value);
        elseif type(value) == "table" then
            if value.className and value.className == "Vector2" then
                return Vector2.New(vector.x - value.x, vector.y - value.y);
            else
                error("attempt to perform arithmetic on " .. vector.className .. " and table");
            end
        else
            error("attempt to perform arithmetic on " .. vector.className .. " and " .. type(value));
        end
    end
end

function Vector2.Multiply(vector, value)
    if vector.className and vector.className ~= "Vector2" then
        error("Invalid Vector2 object");
    else
        if type(value) == "number" then
            return Vector2.New(vector.x * value, vector.y * value);
        elseif type(value) == "table" then
            if value.className and value.className == "Vector2" then
                return Vector2.New(vector.x * value.x, vector.y * value.y);
            else
                error("attempt to perform arithmetic on " .. vector.className .. " and table");
            end
        else
            error("attempt to perform arithmetic on " .. vector.className .. " and " .. type(value));
        end
    end
end

function Vector2.Divide(vector, value)
    if vector.className and vector.className ~= "Vector2" then
        error("Invalid Vector2 object");
    else
        if type(value) == "number" then
            return Vector2.New(vector.x / value, vector.y / value);
        elseif type(value) == "table" then
            if value.className and value.className == "Vector2" then
                return Vector2.New(vector.x / value.x, vector.y / value.y);
            else
                error("attempt to perform arithmetic on " .. vector.className .. " and table");
            end
        else
            error("attempt to perform arithmetic on " .. vector.className .. " and " .. type(value));
        end
    end
end

function Vector2.Length(vector)
    if vector.className and vector.className ~= "Vector2" then
        error("Invalid Vector2 object");
    else
       return math.sqrt(Vector2.LengthSqr(vector));
    end
end

function Vector2.LengthSqr(vector)
    if vector.className and vector.className ~= "Vector2" then
        error("Invalid Vector2 object");
    else
        return vector.x^2 + vector.y^2;
    end
end

function Vector2.Distance(vector1, Vector2)
    if (vector1.className and vector1.className ~= "Vector2") or (Vector2.className and Vector2.className ~= "Vector2") then
        error("Invalid Vector2 object");
    else
        local distance = (vector2.x - vector1.x)^2 + (vector2.y - vector1.y)^2;
        return math.sqrt(distance);
    end
end

function Vector2.Normalize(vector)
    if vector.className and vector.className ~= "Vector2" then
        error("Invalid Vector2 object");
    else
        return vector/vector:Length();
    end
end

function Vector2.Equals(vector, compare)
    if (vector.className and vector.className ~= "Vector2") or (compare.className and compare.className ~= "Vector2") then
        error("Invalid Vector2 object");
    else
        local difference = vector - compare;
        return math.abs(difference.x) + math.abs(difference.y) == 0;
    end
end

-- Finialization so you can actually create "objects"
Vector2.__index = Vector2
return Vector2
