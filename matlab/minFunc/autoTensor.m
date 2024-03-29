function [f,g,H,T] = autoTensor(x,useComplex,funObj,varargin)
% [f,g,H,T] = autoTensor(x,useComplex,funObj,varargin)
% Numerically compute Tensor of 3rd-derivatives of objective function from Hessian values

p = length(x);

if useComplex % Use Complex Differentials
    mu = 1e-150;

    diff = zeros(p,p,p);
    for j = 1:p
        e_j = zeros(p,1);
        e_j(j) = 1;
        [f(j) g(:,j) diff(:,:,j)] = funObj(x + mu*i*e_j,varargin{:});
    end
    f = mean(real(f));
    g = mean(real(g),2);
    H = mean(real(diff),3);
    T = imag(diff)/mu;
else % Use finite differencing
    mu = 2*sqrt(1e-12)*(1+norm(x))/norm(p);
    
    [f,g,H] = funObj(x,varargin{:});
    diff = zeros(p,p,p);
    for j = 1:p
        e_j = zeros(p,1);
        e_j(j) = 1;
        [junk1 junk2 diff(:,:,j)] = funObj(x + mu*e_j,varargin{:});
    end
    T = (diff-repmat(H,[1 1 p]))/mu;
end
