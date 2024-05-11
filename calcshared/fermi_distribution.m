function f = fermi_distribution(epsilon, mu, k_B, Temperature, type)
    % Calculate the Fermi-Dirac distribution
    % for electrons (type='e') and holes (type='h')

    if type == 'e'
        f = 1 ./ (exp((epsilon - mu) / (k_B * Temperature)) + 1);
    elseif type == 'h'
        f = 1 ./ (exp((epsilon + mu) / (k_B * Temperature)) + 1);
    else
        error('Invalid type. Choose either "e" for electron or "h" for hole.');
    end
end