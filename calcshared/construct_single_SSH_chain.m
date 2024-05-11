function H_single_chain = construct_single_SSH_chain(t_u, t_v, Delta, mu, Nx_cell)
    H_intra_BdG = [-mu, 0; 0, mu];
    H_inter_u_BdG = [-t_u, -Delta; Delta', t_u'];
    H_inter_v_BdG = [-t_v, -Delta; Delta', t_v'];
    H_intra_ssh = [H_intra_BdG, H_inter_v_BdG; H_inter_v_BdG', H_intra_BdG];
    H_inter_ssh = [zeros(2), zeros(2); H_inter_u_BdG, zeros(2)];
    
    H_single_chain = kron(eye(Nx_cell), H_intra_ssh) + kron(diag(ones(Nx_cell-1, 1), 1), H_inter_ssh) + kron(diag(ones(Nx_cell-1, 1), -1), H_inter_ssh');
end
