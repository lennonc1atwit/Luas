
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
	0,  4,	16,	28,	40,	52,	64,	73,	70,	58,	46,	34,	22,	10,		
    0,	0,	1,	13,	25,	37,	49,	61,	73,	67,	55,	43,	31,	19,	
    7,	0,	61,	62,	63,	64,	65,	66,	67,	68,	69,	70,	71,	72,				
    61,	49,	50,	51,	52,	53,	54,	55,	56,	57,	58,	59,	60,	49,	
    37,	38,	39,	40,	41,	42,	43,	44,	45,	46,	47,	48,	37,	25,	
    26,	27,	28,	29,	30,	31,	32,	33,	34,	35,	36,	25,	13,	14,	
    15,	16,	17,	18,	19,	20,	21,	22,	23,	24,	13,	1,	2,	3,	
    4,	5,	6,	7,	8,	9,	10,	11,	12, 1
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

    -- matrix setup is correct
	matCapsuleRotationSpace = VectorMatrix(Vector3(0, 0, 1))
    matCapsuleSpace = VectorMatrix(vCapNorm)
   
    -- v stores transformed points to then draw
    local v = {}
    local vLean = (vEnd - vStart)
    for i = 1, #capsuleVertPositions do

        local vecCapsuleVert = Vector3(capsuleVertPositions[i][1], capsuleVertPositions[i][2], capsuleVertPositions[i][3])

        -- rotate vectors
        vecCapsuleVert = VectorRotate(vecCapsuleVert, matCapsuleRotationSpace)
        vecCapsuleVert = VectorRotate(vecCapsuleVert, matCapsuleSpace)
        
        -- scale vectors
        vecCapsuleVert = vecCapsuleVert * flRadius
        if capsuleVertPositions[i][3] > 0 then
            vecCapsuleVert = vecCapsuleVert + vLean 
        end
        
        v[i] = vecCapsuleVert + vStart
    end

    return v
end
