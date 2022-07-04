%% Cell type:markdown id:0aac5da7-745c-4eda-847a-3d0d07a1bb9b tags:

# This is a markdown cell

This paragraph has
With
Many
Lines. How we will he handle MR notes?

But I can add another paragraph

%% Cell type:raw id:faecea5b-de0a-49fa-9a3a-61c2add652da tags:

This is a raw cell
With
Multiple lines

%% Cell type:code id:893ca2c0-ab75-4276-9dad-be1c40e16e8a tags:

``` python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
```

%% Cell type:code id:0d707fb5-226f-46d6-80bd-489ebfb8905c tags:

``` python
np.random.seed(42)
```

%% Cell type:code id:35467fcf-28b1-4c7b-bb09-4cb192c35293 tags:senoid

``` python
x = np.linspace(0, 4*np.pi,50)
y = np.sin(x)

plt.plot(x, y)
```

%% Output

    [<matplotlib.lines.Line2D at 0x123e39370>]

    ![](data:image/png;base64,some_invalid_base64_image_here)

%% Cell type:code id:dc1178cd-c46d-4da3-9ab5-08f000699884 tags:

``` python
df = pd.DataFrame({"x": x, "y": y})
```

%% Cell type:code id:6e749b4f-b409-4700-870f-f68c39462490 tags:some-table

``` python
df[:2]
```

%% Output

              x         y
    0  0.000000  0.000000
    1  0.256457  0.253655

%% Cell type:code id:0ddef5ef-94a3-4afd-9c70-ddee9694f512 tags:

``` python
```
