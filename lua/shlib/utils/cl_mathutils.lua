function SHLIB:RotateMatrix(matr, x, y, w, h, ang)
    matr:Translate(Vector(x + w / 2, y + h / 2, 0))
    matr:SetAngles(Angle(0, ang, 0))
    matr:Translate(Vector(-x - w / 2, -y - h / 2, 0))

    return matr
end