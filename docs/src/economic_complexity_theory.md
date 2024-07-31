# Economic Complexity

The Economic Complexity Index (ECI) and the product complexity index (PCI) are metrics that infers information about countries’ productive capabilities from their export baskets.

The ECI and PCI measures are calculated using an algorithm that operates on a binary country-product matrix ``M`` with elements ``M_{cp}=1`` if country ``c`` has a revealed comparative advantage (RCA) > 1 in product ``p``, where RCA is calculate using the Balassa index:

```math 
    \begin{equation}
        RCA_{c,p} =\dfrac{x(c,p)}{\sum_i x(c,p)} \Bigg/  \dfrac{\sum_c x(c,p)}{\sum_{c,p} x(c,p)}
    \end{equation}
```

where ``x_{cp}`` is country ``c``'s exports of product ``p``. RCA  measures whether a country `` c`` exports more of a product `` p``, as a share of its total exports, than the "average" country (`` RCA>1`` not ``RCA<1``). 


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
