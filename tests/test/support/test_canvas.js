
// teal: 0, 128, 128
// grey: 192, 192, 192

function testGraphs(checkId) {

  var result = true;

  // loop through each metric and test each canvas
  $("div.check[check_id='" + checkId + "'] div.metric div.box").each(function(m, metric) {

    var i = 0;
    $(metric).find("div.graph_container div.graph canvas").each(function(c, canvas) {
      i++;
      if (i == 1 && getPixelPct(canvas, 66, 139, 202) == 0) {
        // blue graph line is missing
        if ($(metric).find("h5.title a").text().toLowerCase().indexOf("_wait") >= 0) {
          // it's ok if some graphs don't have a line
          // in this case: connections by state - time_wait, close_wait, etc may only report one value
          return;
        }

        result = false;
      } else if (i == 2 && getPixelPct(canvas, 192, 192, 192) == 0) {
        // look for grey grid lines
        // TODO don't know where the grid lines actually are
        //      they appear to be on the first canvas but don't see them there
        // result = false;
      }
    });

  });

  return result;
}

function getTotalPixels(canvas) {
  return canvas.height * canvas.width;
}

function getPixelPct(canvas, r, g, b) {
  return getPixelAmount(canvas, r, g, b) / getTotalPixels(canvas);
}

function getPixelAmount(canvas, r, g, b) {
  var cx = canvas.getContext('2d');
  var pixels = cx.getImageData(0, 0, canvas.width, canvas.height);
  var all = pixels.data.length;
  var amount = 0;
  for (i = 0; i < all; i += 4) {
    if (pixels.data[i] === r &&
        pixels.data[i + 1] === g &&
        pixels.data[i + 2] === b) {
      amount++;
    }
  }
  return amount;
};
