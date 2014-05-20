function b = im2col_AB(a,block)
padval = 0.0;

[ma,na] = size(a);
m = block(1); n = block(2);

if any([ma na] < [m n]) % if neighborhood is larger than image
    b = zeros(m*n,0);
    return
end

% Create Hankel-like indexing sub matrix.
mc = block(1); nc = ma-m+1; nn = na-n+1;
cidx = (0:mc-1)'; ridx = 1:nc;
t = cidx(:,ones(nc,1)) + ridx(ones(mc,1),:);    % Hankel Subscripts
tt = zeros(mc*n,nc);
rows = 1:mc;
for i=0:n-1,
    tt(i*mc+rows,:) = t+ma*i;
end
ttt = zeros(mc*n,nc*nn);
cols = 1:nc;
for j=0:nn-1,
    ttt(:,j*nc+cols) = tt+ma*j;
end

% If a is a row vector, change it to a column vector. This change is
% necessary when A is a row vector and [M N] = size(A).
if ndims(a) == 2 && na > 1 && ma == 1
    a = a(:);
end
b = a(ttt);
    
% % Pad A if size(A) is not divisible by block.
% [m,n] = size(a);
% mpad = rem(m,block(1)); if mpad>0, mpad = block(1)-mpad; end
% npad = rem(n,block(2)); if npad>0, npad = block(2)-npad; end
% aa = mkconstarray2(class(a), padval, [m+mpad n+npad]);
% aa(1:m,1:n) = a;
% 
% [m,n] = size(aa);
% mblocks = m/block(1);
% nblocks = n/block(2);
% 
% b = mkconstarray2(class(a), 0, [prod(block) mblocks*nblocks]);
% x = mkconstarray2(class(a), 0, [prod(block) 1]);
% rows = 1:block(1); cols = 1:block(2);
% for i=0:mblocks-1,
%     for j=0:nblocks-1,
%         x(:) = aa(i*block(1)+rows,j*block(2)+cols);
%         b(:,i+j*mblocks+1) = x;
%     end
% end
% 
% 
%     function out = mkconstarray2(class, value, size)
%         %MKCONSTARRAY creates a constant array of a specified numeric class.
%         %   A = MKCONSTARRAY(CLASS, VALUE, SIZE) creates a constant array
%         %   of value VALUE and of size SIZE.
%         
%         %   Copyright 1993-2003 The MathWorks, Inc.
%         %   $Revision: 1.8.4.1 $  $Date: 2003/01/26 06:00:35 $
%         
%         out = repmat(feval(class, value), size);
%         
%     end

end