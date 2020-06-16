local a, b, c = Vector2.New(1, 1), Vector2.New(2, 2), Vector2.New(3, 3)

print("Vector addition")
print(a + b)
print(a:Add(b))
print(Vector2.Add(a, b))

print("Scalar addition")
print(a + 2)
print(a:Add(2))
print(Vector2.Add(a, 2))

print("Vector subtraction")
print(a - b)
print(a:Subtract(b))
print(Vector2.Subtract(a, b))

print("Scalar subtraction")
print(a - 2)
print(a:Subtract(2))
print(Vector2.Subtract(a, 2))

print("Vector multiplication")
print(a * b)
print(a:Multiply(b))
print(Vector2.Multiply(a, b))

print("Scalar multiplication")
print(a * 2)
print(a:Multiply(2))
print(Vector2.Multiply(a, 2))

print("Vector division")
print(a / b)
print(a:Divide(b))
print(Vector2.Divide(a, b))

print("Scalar division")
print(a / 2)
print(a:Divide(2))
print(Vector2.Divide(a, 2))

print("Length")
print(Vector2.Length(c))
print(c:Length())

print("Length sqr")
print(Vector2.LengthSqr(c))
print(c:LengthSqr())

print("negation")
print(-c);

print("normalize")
print(Vector2.Normalize(c));
print(c:Normalize())

print("equality")
print(a == Vector2.New(1,2));

print("indexing")
c.x = 10
c.y = 10
print(c)
