$(document).ready(function(){
  var options = {
    bezierCurve : true,
    legend: {
      display: false,
    },
    scales: {
      xAxes: [{
        gridLines: {
          display: false,
          drawBorder: false,
        },
        ticks: {
          display: false,
        }
      }],
      yAxes: [{
        gridLines: {
            display: false,
            drawBorder: false,
        },
        ticks: {
          display: false,
          beginAtZero: true,
        }
      }]
    },
    elements: {
        point:{
            radius: 0
        }
    }
  };

  var charts = document.getElementsByClassName("crypt-marketcap-canvas");
  if(charts.length > 0){
    for( let chart of charts ){
      let data = JSON.parse(chart.dataset.charts);
      let bg = chart.dataset.bg;
      let border = chart.dataset.border;

      let canvas = chart.querySelector('canvas');
      let ctx = canvas.getContext('2d');

      var gradient = ctx.createLinearGradient(0, 0, 0, 70);
        gradient.addColorStop(0, "transparent" );
        gradient.addColorStop(1, "transparent");
      let lineChartData = {
        labels : ["1","2","3","4","5","6","7","8","9"],
        datasets : [
            {
                backgroundColor : gradient,
                borderColor : '#' + border,
                data : data,
                bezierCurve : true
            }
        ]  
      }
      new Chart(ctx, {
        type:"line",
        data:lineChartData,
        options:options
      });
    }
  }


  var optionsForIndiv = {
    bezierCurve : true,
    legend: {
      display: false,
    },
    scales: {
      xAxes: [{
        gridLines: {
          display: false,
          drawBorder: false,
        },
        ticks: {
          display: false,
        }
      }],
      yAxes: [{
        gridLines: {
            display: false,
            drawBorder: false,
        },
        ticks: {
          display: false,
          beginAtZero: true,
        }
      }]
    },
    elements: {
        point:{
            radius: 0
        }
    }
  };

  var chartsIndiv = document.getElementsByClassName("crypt-individual-marketcap");
  if(chartsIndiv.length > 0){
    for( let chart of chartsIndiv ){
      let data = JSON.parse(chart.dataset.charts);
      let bg = chart.dataset.bg;
      let border = chart.dataset.border;

      let canvas = chart.querySelector('canvas');
      let ctx = canvas.getContext('2d');

      var gradient = ctx.createLinearGradient(0, 0, 0, 150);
        gradient.addColorStop(0, "#" + bg);
        gradient.addColorStop(1, "transparent");
      let lineChartData = {
        labels : ["1","2","3","4","5","6","7","8","9"],
        datasets : [
            {
                backgroundColor : gradient,
                borderColor : '#' + border,
                data : data,
                bezierCurve : true
            }
        ]  
      }
      new Chart(ctx, {
        type:"line",
        data: lineChartData,
        options: optionsForIndiv
      });
    }
  }
})