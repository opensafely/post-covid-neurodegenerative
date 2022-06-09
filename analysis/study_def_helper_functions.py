def generate_ethnicity_dictionary(n_groups: int) -> dict:
    """
    project-specific function to generate dictionary of 6-group ethnicity
    values and logical definitions combining three source ethnicity variables
    to be used within a patients.categorised_as() statement
    """
    eth_dict = {"0": "DEFAULT"}
    for n in range(1, n_groups + 1):
        eth_dict[
            str(n)
        ] = f""" 
            (cov_ethnicity_sus="{n}" AND cov_ethnicity_gp_opensafely="" AND cov_ethnicity_gp_primis="") OR
            (cov_ethnicity_gp_opensafely="{n}" AND cov_ethnicity_gp_opensafely_date >= cov_ethnicity_gp_primis_date ) OR
            (cov_ethnicity_gp_primis="{n}" AND cov_ethnicity_gp_primis_date > cov_ethnicity_gp_opensafely_date)            
            """
    return eth_dict


def generate_deprivation_ntile_dictionary(ntiles: int) -> dict:
    """
    create dictionary of n:logical defition of ntiles of index of multiple deprivation
    values for arbitrary n, to be used with patients.categorised_as().
    """
    dep_dict = {"0": "DEFAULT"}
    for n in range(1, ntiles + 1):
        l = f"index_of_multiple_deprivation >={1 if n==1 else f'32844*{n-1}/{ntiles}'}"
        r = f" AND index_of_multiple_deprivation < 32844*{n}/{ntiles}"

        dep_dict[str(n)] = l if n == ntiles else l + r

    return dep_dict


def generate_universal_expectations(n_categories: int, zero_category=True) -> dict:
    """
    generate expectations statement for categorical variable of n classes
    each with the value n, universally distributed, with an additional "0"
    category of incidence 0.01.
    """
    equal_ratio = round(1 / n_categories, 2)
    ratios = {str(n): equal_ratio for n in range(1, n_categories)}
    if zero_category == True:
        ratios["0"] = 0.01
    ratios[str(n_categories)] = 1 - sum(ratios.values())

    exp_dict = {"rate": "universal", "category": {"ratios": ratios}}

    return exp_dict