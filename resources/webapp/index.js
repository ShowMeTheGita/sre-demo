const express = require('express');
const app = express();
const port = 4000;

app.get('/', (req, res) => {
  res.send('If you\'re seeing this, the webapp is up');
});

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});
