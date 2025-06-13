function out = be_convsynthesereal(in_V, in_W, H, G)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Project Name: EOG Correction Artifact
% Filename:     be_convsynthesereal.m
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Modified by:  Xavier Leturc
% Created on:   July 21st, 2008
% Revised on:   June 13,  2025
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Notes:        Cette fonction permet de faire la convolution entre les
%               donnees et les filtres reels ou complexes.
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Inputs
%   in_V :      vecteur ou matrice de donnees a traiter;
%   in_W :      vecteur ou matrice de donnees a traiter;
%   H :         filtre complexe H (synthese);
%   G :         filtre complexe G (synthese);
%   n :         nombre de points total;
%   Jcase :     nombre de moment nul;
% Outputs
%   out :       somme des produits de convolution avec H et G.
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    sz1 = size(in_V);  sz2 = size(H);

    if (size(sz1,2) == 2)
        sz1(3) = 1;
    end

    if ~ (any(in_V) || any(in_W))
        out = 0;
        return;
    end

    
    p  = length(H);
    n1 = sz1(2); idx_n1 = n1+1-p:n1;
    n2 = size(in_W,2); idx_n2 = 1:n2-1;

    % Precompute filter coefficients once (no need to reverse in each iteration)
    H_rev = H(end:-1:1);
    G_rev = G(end:-1:1);

    % Preallocate all arrays
    sum1 = zeros(sz1(1), n1 + length(idx_n1), sz1(3));
    sum2 = zeros(sz1(1), n1 + length(idx_n1), sz1(3));
    
    % Preallocate temp arrays outside the loop to avoid memory allocation overhead
    tempV = zeros(sz1(1), n1 + length(idx_n1));
    tempW = zeros(sz1(1), 1 + length(idx_n2) + p );

    for j = 1:sz1(3)

        if any(in_V)
            tempV(:, 1:p)       = in_V(:, idx_n1, j);
            tempV(:, p+1:end)   = in_V(:, :, j);

            sum1(:, :, j)       = filter(H_rev, 1, tempV, [], 2);        % filtering across time (dim 2)
        end

        if any(in_W)
            tempW(:, 1)         = in_W(:, n2, j);
            tempW(:, 2:n2)      = in_W(:, idx_n2, j);
            tempW(:, n2+1:n2+p) = tempW(:, 1:p);
    
            sum2(:, :, j)       = filter(G_rev, 1, tempW, [], 2);
        end

    end
 
    out = sum1(:, p+1:n1+p,:)...
        + sum2(:, p:n2+p-1,:);
    
end