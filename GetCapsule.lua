
local capsuleVertPositions = {
	{ -0.01, -0.01, 1.0 },	{ 0.51, 0.0, 0.86 },	{ 0.44, 0.25, 0.86 },	{ 0.25, 0.44, 0.86 },	{ -0.01, 0.51, 0.86 },	{ -0.26, 0.44, 0.86 },	{ -0.45, 0.25, 0.86 },	{ -0.51, 0.0, 0.86 },	{ -0.45, -0.26, 0.86 },
	{ -0.26, -0.45, 0.86 },	{ -0.01, -0.51, 0.86 },	{ 0.25, -0.45, 0.86 },	{ 0.44, -0.26, 0.86 },	{ 0.86, 0.0, 0.51 },	{ 0.75, 0.43, 0.51 },	{ 0.43, 0.75, 0.51 },	{ -0.01, 0.86, 0.51 },	{ -0.44, 0.75, 0.51 },
	{ -0.76, 0.43, 0.51 },	{ -0.87, 0.0, 0.51 },	{ -0.76, -0.44, 0.51 },	{ -0.44, -0.76, 0.51 },	{ -0.01, -0.87, 0.51 },	{ 0.43, -0.76, 0.51 },	{ 0.75, -0.44, 0.51 },	{ 1.0, 0.0, 0.01 },		{ 0.86, 0.5, 0.01 },
	{ 0.49, 0.86, 0.01 },	{ -0.01, 1.0, 0.01 },	{ -0.51, 0.86, 0.01 },	{ -0.87, 0.5, 0.01 },	{ -1.0, 0.0, 0.01 },	{ -0.87, -0.5, 0.01 },	{ -0.51, -0.87, 0.01 },	{ -0.01, -1.0, 0.01 },	{ 0.49, -0.87, 0.01 },
	{ 0.86, -0.51, 0.01 },	{ 1.0, 0.0, -0.02 },	{ 0.86, 0.5, -0.02 },	{ 0.49, 0.86, -0.02 },	{ -0.01, 1.0, -0.02 },	{ -0.51, 0.86, -0.02 },	{ -0.87, 0.5, -0.02 },	{ -1.0, 0.0, -0.02 },	{ -0.87, -0.5, -0.02 },
	{ -0.51, -0.87, -0.02 },{ -0.01, -1.0, -0.02 },	{ 0.49, -0.87, -0.02 },	{ 0.86, -0.51, -0.02 },	{ 0.86, 0.0, -0.51 },	{ 0.75, 0.43, -0.51 },	{ 0.43, 0.75, -0.51 },	{ -0.01, 0.86, -0.51 },	{ -0.44, 0.75, -0.51 },
	{ -0.76, 0.43, -0.51 },	{ -0.87, 0.0, -0.51 },	{ -0.76, -0.44, -0.51 },{ -0.44, -0.76, -0.51 },{ -0.01, -0.87, -0.51 },{ 0.43, -0.76, -0.51 },	{ 0.75, -0.44, -0.51 },	{ 0.51, 0.0, -0.87 },	{ 0.44, 0.25, -0.87 },
	{ 0.25, 0.44, -0.87 },	{ -0.01, 0.51, -0.87 },	{ -0.26, 0.44, -0.87 },	{ -0.45, 0.25, -0.87 },	{ -0.51, 0.0, -0.87 },	{ -0.45, -0.26, -0.87 },{ -0.26, -0.45, -0.87 },{ -0.01, -0.51, -0.87 },{ 0.25, -0.45, -0.87 },
	{ 0.44, -0.26, -0.87 },	{ 0.0, 0.0, -1.0 }
}

capsuleLineIndices = {
    {0 , 4}, {4 ,16}, {16,28}, {28,40}, {40,52}, {52,64}, {64,73}, {73,70}, {70,58}, {58,46}, {46,34}, {34,22}, {22,10}, {10, 0}, -- Oval 1
    {0 , 1}, {1 ,13}, {13,25}, {25,37}, {37,49}, {49,61}, {61,73}, {73,67}, {67,55}, {55,43}, {43,31}, {31,19}, {19, 7}, {7 , 0}, -- Oval 2
    {61,62}, {62,63}, {63,64}, {64,65}, {65,66}, {66,67}, {67,68}, {68,69}, {69,70}, {70,71}, {71,72}, {72,61}, -- Start Ring 1
    {49,50}, {50,51}, {51,52}, {52,53}, {53,54}, {54,55}, {55,56}, {56,57}, {57,58}, {58,59}, {59,60}, {60,49}, -- Start Ring 2
    {37,38}, {38,39}, {39,40}, {40,41}, {41,42}, {42,43}, {43,44}, {44,45}, {45,46}, {46,47}, {47,48}, {48,37}, -- Start Ring 3
    {25,26}, {26,27}, {27,28}, {28,29}, {29,30}, {30,31}, {31,32}, {32,33}, {33,34}, {34,35}, {35,36}, {36,25}, -- End Ring 1
    {13,14}, {14,15}, {15,16}, {16,17}, {17,18}, {18,19}, {19,20}, {20,21}, {21,22}, {22,23}, {23,24}, {24,13}, -- End Ring 2
    {1 , 2}, {2 , 3}, {3 , 4}, {4 , 5}, {5 , 6}, {6 , 7}, {7 , 8}, {8 , 9}, {9 ,10}, {10,11}, {11,12}, {12, 1}  -- End Ring 3

}

-- rot is a table of vector3's we multiply vec by each coloumn in the matrix to rotate the vector
local function VectorRotate(vec, rot)
    x = vec:Dot(Vector3(rot[1].x, rot[2].x, rot[3].x))
	y = vec:Dot(Vector3(rot[1].y, rot[2].y, rot[3].y))
    z = vec:Dot(Vector3(rot[1].z, rot[2].z, rot[3].z))
	return Vector3(x,y,z)
end

-- Create axis vectors based of a forward vector
local function VectorVectors(forward)
    local right, up

	if math.abs(forward.x) < 0.000001 and math.abs(forward.y) < 0.000001 then
		right = Vector3(0, 1, 0)	
        up = Vector3(-forward.z, 0, 0)
	else
        right = forward:Cross(Vector3(0, 0, 1))
        right:Normalize()
		up = right:Cross(forward)
        up:Normalize()
    end

    return right, up
end

-- Using a forward vector create a matrix of the basis vectors
local function VectorMatrix(forward)
    right, up = VectorVectors(forward)

    local matrix = {}
    matrix[1] = forward
    matrix[2] = -right
    matrix[3] = up
    return matrix
end

function getCapsule(vStart, vEnd, flRadius)
    local vCapNorm = (vStart - vEnd)
    vCapNorm:Normalize()
    -- matrix setup
	matCapsuleRotationSpace = VectorMatrix(Vector3(0, 0, 1))
    matCapsuleSpace = VectorMatrix(vCapNorm)
   
    -- v stores transformed points to then draw
    local v = {}
    for i = 1, #capsuleVertPositions do

        local vecCapsuleVert = Vector3(capsuleVertPositions[i][1], capsuleVertPositions[i][2], capsuleVertPositions[i][3])
        -- rotate vectors
        vecCapsuleVert = VectorRotate(vecCapsuleVert, matCapsuleRotationSpace)
        vecCapsuleVert = VectorRotate(vecCapsuleVert, matCapsuleSpace)
        -- scale vectors
        vecCapsuleVert = vecCapsuleVert * flRadius
        if capsuleVertPositions[i][3] > 0 then
            vecCapsuleVert = vecCapsuleVert + (vEnd - vStart)
        end
        
        v[i] = vecCapsuleVert + vStart
    end

    return v
end
