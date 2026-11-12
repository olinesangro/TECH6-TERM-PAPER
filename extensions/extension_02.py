#--------------------------------------------------------------
# EXTENSION 2: Machine Learning
#--------------------------------------------------------------

# Random state used for sample splitting (train/test, cross-validation) and other RNGs
RANDOM_STATE = 1234
# Scoring metric for cross-validation
SCORING = 'neg_root_mean_squared_error'
# Number of jobs to run in parallel
NUM_JOBS = 4

import pandas as pd

file = 'regdata0.dta'
df = pd.read_stata(file)
print(f'Number of observations: {len(df):,d}')

# PREPARING THE DATA
# Variables used to match sample with Meyersson
complete_case_vars = [
    'hischshr1520m', 'vshr_islam1994', 'partycount', 'lpop1994',
    'ageshr19', 'ageshr60', 'sexr', 'shhs',
    'merkezi', 'merkezp', 'subbuyuk',
]

# Narrower list: pre-treatment-only predictors the model is allowed to see
vars = [
    'vshr_islam1994', 'partycount', 'lpop1994',
    'merkezi', 'merkezp', 'subbuyuk',
]

# Drop rows with missing values. Document the number dropped at each step.
relevant_vars = ['hischshr1520f', 'i94'] + complete_case_vars
for column in sorted(relevant_vars):
    n_missing = df[column].isna().sum()
    if n_missing > 0:
        print(f'Dropping {n_missing:3,d} rows with missing values in {column}')
        df = df.dropna(subset=[column]).copy()

print(f'Number of observations after dropping: {len(df):,d}')

# Name of the target variable
target = 'hischshr1520f'

# Split into training sample (secular towns) and prediction sample (Islamic
# towns). Unlike a random train-test split, this follows actual treatment
# status: the model learns only from untreated (secular) towns, then predicts
# what Islamic towns' education outcomes would have looked like without an
# Islamic mayor. Can't set the a test size as 0.5 and randomize.
secular = df['i94'] == 0

X_train = df.loc[secular, vars]
y_train = df.loc[secular, target]
X_islamic = df.loc[~secular, vars]

print(f'Training observations (secular towns): {len(X_train):,d}')
print(f'Prediction observations (Islamic towns): {len(X_islamic):,d}')

# EXPLORING THE TRAINING DATA
import matplotlib.pyplot as plt
import numpy as np

def plot_histograms(df_data, title=None):
    """
    Plot a histogram for every column in a DataFrame.

    Parameters
    ----------
    df_data : DataFrame
        Numeric columns to plot
    title : str or None
        Optional title for the entire figure
    """
    ncols = df_data.shape[1]
    figsize = (3 * ncols, 2.8)
    fig, axes = plt.subplots(
        1, ncols, figsize=figsize, layout='constrained', squeeze=False
    )
    for i, col in enumerate(df_data.columns):
        ax = axes[0, i]
        ax.hist(df_data[col], bins=40, color='steelblue', ec='white', lw=0.4)
        ax.set_xlabel(col)
        ax.set_ylabel('Number of municipalities')

    if title is not None:
        fig.suptitle(title)
    
    plt.show()


def plot_scatterplots(y_var, df_data):
    """
    Plot one column against every other column in a DataFrame.

    Parameters
    ----------
    y_var : str
        Column name to use on the shared y-axis
    df_data : DataFrame
        Data containing the outcome and numeric predictors
    """
    columns = df_data.columns.drop(y_var)
    nplots = len(columns)
    ncols = min(4, nplots)
    nrows = (nplots + 3) // 4
    figsize = (2.25 * ncols, 2.25 * nrows)
    _, axes = plt.subplots(
        nrows, ncols, figsize=figsize, sharey=True, squeeze=False, layout='constrained'
    )
    axes = axes.ravel()

    for i, col in enumerate(columns):
        ax = axes[i]
        df_ = df_data[[col, y_var]]
        ax.scatter(df_[col], df_[y_var], s=8, alpha=0.3, c='steelblue')

        uniq = df_[col].nunique()
        if uniq <= 12:
            # Treat this as a categorical variable
            means = df_.groupby(col)[y_var].mean()
            xbin, ybin = means.index, means
            ax.set_xticks(sorted(df_data[col].unique()))
        else:
            # Continuous variable
            bins = pd.cut(df_[col], bins=10)
            means = df_.groupby(bins).mean()
            xbin, ybin = means[col], means[y_var]
            ax.locator_params(axis='x', nbins=4)

        ax.plot(xbin, ybin, marker='o', c='black', lw=1, ls='--', ms=3)
        ax.set_xlabel(col)
        if i % 4 == 0:
            ax.set_ylabel(y_var)
        corr = np.corrcoef(df_data[col], df_data[y_var])[0, 1]
        ax.text(
            0.95, 0.05, f'corr = {corr:.2f}',
            transform=ax.transAxes, va='bottom', ha='right', fontsize=8,
        )

    for ax in axes[nplots:]:
        ax.set_visible(False)
    
    plt.show()

# Training sample (secular towns only) for exploration
df_train = df.loc[secular, [target] + vars]

# Histograms in levels
columns = [target, 'partycount']
plot_histograms(df_train[columns], title='Variables in levels')

# Scatterplots of the target against all predictors
plot_scatterplots(target, df_train)

# Correlation of each predictor with the target
corr = df_train.corrwith(df_train[target]).drop(target)
print(corr.sort_values(ascending=False, key=abs).round(2).to_string())


# ORDINARY LEAST SQUARES
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import PolynomialFeatures, StandardScaler

def make_model(estimator):
    """
    Build a polynomial regression pipeline.

    Parameters
    ----------
    estimator : object
        Regression estimator used after preprocessing

    Returns
    -------
    Unfitted pipeline containing preprocessing and regression
    """
    pipe = Pipeline(
        [
            ('input_scale', StandardScaler()),
            ('poly', PolynomialFeatures(include_bias=False)),
            ('scale', StandardScaler()),
            ('model', estimator),
        ]
    )
    return pipe


def plot_ols_validation_curve(ols_cv):
    """
    Plot training and validation RMSE against polynomial degree.

    Parameters
    ----------
    ols_cv : GridSearchCV
        Fitted GridSearchCV object for OLS regression
    """
    df_ols = pd.DataFrame(ols_cv.cv_results_)
    degrees = df_ols['param_poly__degree']
    train_score = -df_ols['mean_train_score']
    test_score = -df_ols['mean_test_score']
    _, ax = plt.subplots(figsize=(5, 3), layout='constrained')

    colors = ['#1f78b4', '#e31a1c']

    ax.plot(degrees, train_score, c=colors[0], marker='o', label='Training')
    ax.plot(degrees, test_score, c=colors[1], marker='o', label='Validation')
    ax.set_xticks(degrees)
    ax.set_xlabel('Polynomial degree')
    ax.set_ylabel('RMSE in female HS completion share')
    ax.set_title('Validation curve for polynomial degree')
    ax.legend()

    plt.show()


# Number of polynomial features generated at each degree
for degree in [1, 2, 3]:
    poly = PolynomialFeatures(degree=degree, include_bias=False)
    poly.fit(X_train)
    print(f'Degree {degree}: {poly.n_output_features_:3d} polynomial columns')


# Cross-validation
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import GridSearchCV, KFold

# Splitter used for cross-validation
cv = KFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)

# Scoring metric used for cross-validation
scoring = SCORING

# Candidate polynomial degrees
degrees = [1, 2, 3]

# Parameter grid
param_grid = {'poly__degree': degrees}

# Estimator pipeline for OLS
pipe_ols = make_model(LinearRegression())

# Define the GridSearchCV object for OLS
ols_cv = GridSearchCV(
    pipe_ols,
    param_grid=param_grid,
    cv=cv,
    scoring=scoring,
    refit=True,
    return_train_score=True,
    n_jobs=NUM_JOBS,
)

# Run cross-validation
ols_cv.fit(X_train, y_train)


# Cross-validation results and validation curve
# Store the best polynomial degree
degree_ols = ols_cv.best_params_['poly__degree']

# Store the best CV RMSE
rmse_ols = -ols_cv.best_score_

print(f'OLS polynomial degree: {degree_ols}')
print(f'OLS CV RMSE: {rmse_ols:.4f}')

plot_ols_validation_curve(ols_cv)

# RIDGE REGRESSION
def plot_validation_curves(search, model_name):
    """
    Plot validation RMSE against alpha for each polynomial degree.

    Parameters
    ----------
    search : object
        Fitted grid search over polynomial degree and model alpha
    model_name : str
        Model name used in the plot title
    """
    df_results = pd.DataFrame(search.cv_results_)
    degree_col = 'param_poly__degree'
    colors = ['#1f78b4', '#e31a1c', '#33a02c']

    _, ax = plt.subplots(figsize=(5.5, 3.2), layout='constrained')
    for i, (degree, df_group) in enumerate(df_results.groupby(degree_col)):
        df_group = df_group.sort_values('param_model__alpha')
        alphas = df_group['param_model__alpha']
        rmse = -df_group['mean_test_score']
        ax.plot(alphas, rmse, c=colors[i], label=f'Degree {degree}')

    best = df_results.loc[search.best_index_]
    ax.scatter(
        best['param_model__alpha'], -best['mean_test_score'], c='black', zorder=3
    )
    ax.set_xscale('log')
    ax.set_xlabel(r'Regularization strength $\alpha$')
    ax.set_ylabel('CV RMSE in female HS completion share')
    ax.set_title(f'Validation curve for {model_name}')
    ax.legend()

    plt.show()

# Ridge cross-validation
from sklearn.linear_model import Ridge

# Define the candidate alphas for Ridge regression
ridge_alphas = np.logspace(-2, 2, num=100)

# Define the parameter grid for Ridge regression
ridge_param_grid = {'poly__degree': degrees, 'model__alpha': ridge_alphas}

# Define the Ridge regression pipeline
pipe_ridge = make_model(Ridge())

# Define the GridSearchCV object for Ridge regression
ridge_cv = GridSearchCV(
    pipe_ridge,
    param_grid=ridge_param_grid,
    cv=cv,
    scoring=scoring,
    refit=True,
    n_jobs=NUM_JOBS,
)

# Run cross-validation
ridge_cv.fit(X_train, y_train)

alpha_ridge = ridge_cv.best_params_['model__alpha']
degree_ridge = ridge_cv.best_params_['poly__degree']
rmse_ridge = -ridge_cv.best_score_

# Cross-validation results
print(f'Ridge polynomial degree: {degree_ridge}')
print(f'Ridge CV alpha: {alpha_ridge:.4g}')
print(f'Ridge CV RMSE: {rmse_ridge:.4g}')

# Validation curve
plot_validation_curves(ridge_cv, 'Ridge')



# LASSO
from sklearn.linear_model import Lasso

# Define the candidate alphas for Lasso regression
lasso_alphas = np.logspace(-4, -1, num=100)

# Define the parameter grid for Lasso regression
lasso_param_grid = {'poly__degree': degrees, 'model__alpha': lasso_alphas}

# Define the Lasso estimator as last step in the pipeline
lasso_model = Lasso(
    max_iter=1_000_000,
    tol=1e-6,
    precompute=True,
    selection='random',
    random_state=RANDOM_STATE,
)
# Define the Lasso regression pipeline
pipe_lasso = make_model(lasso_model)

# Define the GridSearchCV object for Lasso regression
lasso_cv = GridSearchCV(
    pipe_lasso,
    param_grid=lasso_param_grid,
    cv=cv,
    scoring=scoring,
    refit=True,
    n_jobs=NUM_JOBS,
)

# Run cross-validation
lasso_cv.fit(X_train, y_train)

# Cross-validation results
alpha_lasso = lasso_cv.best_params_['model__alpha']
degree_lasso = lasso_cv.best_params_['poly__degree']
rmse_lasso = -lasso_cv.best_score_
print(f'Lasso polynomial degree: {degree_lasso}')
print(f'Lasso CV alpha: {alpha_lasso:.4g}')
print(f'Lasso CV RMSE: {rmse_lasso:.4g}')

lasso_best = lasso_cv.best_estimator_.named_steps['model']
n_nonzero = np.count_nonzero(np.abs(lasso_best.coef_) > 1e-8)
print(f'Nonzero coefficients: {n_nonzero} out of {len(lasso_best.coef_)}')

# Validation curve
plot_validation_curves(lasso_cv, 'Lasso')



# COMPARE THE RESULTS
model_names = ['OLS', 'Ridge', 'Lasso']
searches = [ols_cv, ridge_cv, lasso_cv]

# Compile a summary table of the cross-validation results
rows = []
for model_name, search in zip(model_names, searches):
    model = search.best_estimator_.named_steps['model']

    rows.append(
        {
            'Model': model_name,
            'Degree': search.best_params_['poly__degree'],
            'Alpha': search.best_params_.get('model__alpha', np.nan),
            '# Coefs': len(model.coef_),
            '# Non-zero coefs': np.count_nonzero(np.abs(model.coef_) > 1e-8),
            'CV RMSE': -search.best_score_,
        }
    )

df_cv = pd.DataFrame(rows).set_index('Model')
print(df_cv.to_string(float_format='{:.5g}'.format))

# Predict the counterfactual outcome: what each Islamic town's female
# HS completion would have been without an Islamic mayor, using the
# model trained only on secular towns
pred_islamic_ols = ols_cv.best_estimator_.predict(X_islamic)
pred_islamic_ridge = ridge_cv.best_estimator_.predict(X_islamic)
pred_islamic_lasso = lasso_cv.best_estimator_.predict(X_islamic)

# The actual, observed outcome for those same towns
y_islamic = df.loc[~secular, target]

# Estimated effect: actual outcome minus predicted counterfactual
effect_ols = y_islamic.values - pred_islamic_ols
effect_ridge = y_islamic.values - pred_islamic_ridge
effect_lasso = y_islamic.values - pred_islamic_lasso

print(f'OLS effect:     mean = {effect_ols.mean():.4f},   median = {np.median(effect_ols):.4f}')
print(f'Ridge effect:   mean = {effect_ridge.mean():.4f},   median = {np.median(effect_ridge):.4f}')
print(f'Lasso effect:   mean = {effect_lasso.mean():.4f},   median = {np.median(effect_lasso):.4f}')