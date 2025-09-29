Import-Module PSWriteHTML
# Data
$labels = @('Turbine A','Turbine B','Turbine C','Turbine D','Turbine E','Turbine F')
$values = @(3.4,3.8,3.1,4.0,3.6,3.2)

$OutputPath = "MyBarChart.html"

Dashboard -Name 'Simple Bar Chart' -FilePath $OutputPath {
    Add-HTMLStyle -Css @{
        'html, body' = @{'background-color' = 'black'; 'color' = 'white' }
        '.defaultSection' = @{'background-color' = 'black'; 'border' = 'none'; 'box-shadow'  = 'none'  }
        '.apexcharts-canvas' = @{ 'background' = 'black !important' }
        '.apexcharts-xaxis text, .apexcharts-yaxis text, .apexcharts-legend-text' = @{ 'fill'  = 'white'; 'color' = 'white !important' }
    }

    Chart -Height 540 -Width 960 {
        ChartTheme -Mode Dark -Palette 'palette4'
        ChartLegend -Name 'Average Output (MW)'
        ChartBarOptions -Vertical
        ChartAxisX -Names $labels -TitleText 'Wind Turbine'
        ChartAxisY -TitleText 'Output (MW)' -MinValue 0

        for ($i = 0; $i -lt $labels.Count; $i++) {
            ChartBar -Name $labels[$i] -Value $values[$i] -Color 'white'
        }
    }
} -Show