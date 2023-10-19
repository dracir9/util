function alpha = normAngleRad(alpha)
%NORMANGLE Normalize angle between -pi and pi radians
    alpha = mod(alpha + pi, 2*pi) - pi;
end

