function H_single_chain = construct_kitaevchain(Nx, t, mu, Delta)
% Constructs the Hamiltonian for a Kitaev chain
%
% Inputs:
%   - Nx: Number of sites in the chain
%   - t: Hopping strength
%   - mu: Chemical potential
%   - Delta: Pairing potential
%
% Output:
%   - H_single_chain: Hamiltonian matrix for the Kitaev chain

% Kitaev chain Hamiltonian components
H_intra_BdG = [-mu, 0; 0, mu];
H_inter_BdG = [-t, -Delta; Delta', t'];

% Construct the Hamiltonian matrix
H_single_chain = kron(eye(Nx), H_intra_BdG) + ...
                 kron(diag(ones(Nx-1,1), 1), H_inter_BdG) + ...
                 kron(diag(ones(Nx-1,1), -1), H_inter_BdG');
end