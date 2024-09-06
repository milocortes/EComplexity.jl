# Economic Complexity

The Economic Complexity Index (ECI) and the product complexity index (PCI) are metrics that infers information about countries’ productive capabilities from their export baskets.

The ECI and PCI measures are calculated using an algorithm that operates on a binary country-product matrix ``M`` with elements ``M_{cp}=1`` if country ``c`` has a revealed comparative advantage (RCA) > 1 in product ``p``, where RCA is calculate using the Balassa index:

```math 
    \begin{equation}
        RCA_{c,p} =\dfrac{x(c,p)}{\sum_i x(c,p)} \Bigg/  \dfrac{\sum_c x(c,p)}{\sum_{c,p} x(c,p)}
    \end{equation}
```

where ``x_{cp}`` is country ``c``'s exports of product ``p``. RCA  measures whether a country `` c`` exports more of a product `` p``, as a share of its total exports, than the "average" country (`` RCA>1`` not ``RCA<1``). 


## [The ECI and PCI (Mealy, P., Farmer, J. D., & Teytelboym, A. 2019)](https://www.science.org/doi/10.1126/sciadv.aau1705)

The ECI and PCI were originally defined through an iterative, self-referential method of reflections algorithm that first calculates diversity and ubiquity and then recursively uses the information in one to correct the other. However, it can be shown (G. Caldarelli, et at, 2012)(M. Cristelli, et al, 2013) that the method of reflections is equivalent to finding the eigenvalues of a matrix ``\tilde{M}`` whose rows and columns correspond to countries and whose entries are given by (in matrix notation)

```math 
    \begin{equation}
        \tilde{M} = D^{-1}MU^{-1}M^{'}
    \end{equation}    
```

where ``D`` is the diagonal matrix formed from the vector of country diversity values and ``U`` is the diagonal matrix formed from the vector of product ubiquity values.

When applied to country trade data, one can think of ``\tilde{M}`` as a diversity-weighted (or normalized) similarity matrix, reflecting how similar two countries’ export baskets are.

Further, from Eq. 2, we can see that

```math 
    \begin{equation}
        \tilde{M} = D^{-1}S
    \end{equation}    
```

where ``S = MU^{-1}M^{'}`` is a symmetric similarity matrix in which each element ``S_{cc^{'}}`` represents the products that country c has in common
with country ``c^{'}``, weighted by the inverse of each product’s ubiquity.

Since ``\tilde{M}`` is a row-stochastic matrix (its rows sum to one), its entries can also be interpreted as conditional transition probabilities in a
Markov transition matrix. The ECI is defined as the eigenvector associated with the second largest right eigenvalue of ``\tilde{M}``. This eigenvector determines a “diffusion distance” between the stationary probabilities of states reached by a random walk described by this Markov transition matrix.

The PCI is symmetrically defined by transposing the country-product matrix ``M`` and finding the eigenvector corresponding to the second largest right eigenvalue of ``\tilde{M}``, given by

```math 
    \begin{equation}
        \hat{M} = U^{-1}M^{'}D^{-1}M
    \end{equation}    
```

## Proximity
Formally, the proximity ``\phi`` between products ``i`` and ``j`` is the minimum of the pairwise conditional probabilities of a country exporting a good given that it exports another.

```math 
    \begin{equation}
        \phi_{i,j} = \min \big\lbrace P(RCAx_i|RCAx_j),P(RCAx_j|RCAx_i) \big\rbrace 
    \end{equation}    
```


## Distance
```math
\begin{equation}
    d_{cp} = \dfrac{\sum_{p'}(1-M_{cp'}) \phi_{pp'}}{\sum_{p'} \phi_{pp'}}
\end{equation}
```
