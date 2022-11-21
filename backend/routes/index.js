var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'Express' });
});
router.get('/api', function(req, res, next) {
  res.send('This is api root')
});
router.get('/api/hoge', function(req, res, next) {
  res.send('api hogehoge')
});
router.get('/api/headers', function(req, res, next) {
  res.send(req.headers)
});

module.exports = router;
