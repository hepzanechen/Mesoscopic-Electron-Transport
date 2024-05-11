function Sigma_lead = self_energy_decimation(epsilon, t, epsilon0, V1alpha, type)
    % Given matrices and parameters, small imaginary part is added to H00 for regularization
    slice_dim = size(t,1);

    switch type
        case 'hole'
            omega = (-epsilon +1d-2*j) * eye(slice_dim);
        otherwise % Default to 'particle'
            omega = (epsilon + 1d-2*j) * eye(slice_dim);
    end

    H00 = epsilon0;
    H01 = t;
    H10 = t';
    desiredAccuracy = 1e-25; % Desired accuracy threshold

    % Initialize variables
    alpha = (H01 / (omega - H00)) * H01;
    beta = (H10 / (omega - H00)) * H10;
    epsilon_s = H00 + (H01 / (omega - H00)) * H10;
    epsilon = epsilon_s + (H10 / (omega - H00)) * H01;

    % Iterate until desired accuracy is reached
    while norm(alpha) > desiredAccuracy
        alpha_prev = alpha;
        beta_prev = beta;
        epsilon_prev = epsilon;
        epsilon_s = epsilon_s + (alpha_prev / (omega - epsilon_prev)) * beta_prev;
        alpha = (alpha_prev / (omega - epsilon_prev)) * alpha_prev;
        beta = (beta_prev / (omega - epsilon_prev)) * beta_prev;
        epsilon = epsilon_prev + (alpha_prev / (omega - epsilon_prev)) * beta_prev + (beta_prev / (omega - epsilon_prev)) * alpha_prev;
    end

    % Calculate self-energy
    g = inv(omega - epsilon_s);
    Sigma_lead = V1alpha * g * V1alpha';

    % For holes, use complex conjugate
    if strcmp(type, 'hole')
        Sigma_lead = -conj(Sigma_lead);
    end
end