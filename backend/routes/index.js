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
  res.send('api HOGE')
});
router.get('/api/login', function(req, res, next) {
  res.redirect(301, '/')
});
router.get('/api/logout', function(req, res, next) {
  res.clearCookie('AWSELBAuthSessionCookie-0')
  res.send('logout. cookie has been deleted.')
});
router.get('/api/new', function(req, res, next) {
  res.send('api HOGE')
});
router.get('/api/headers', function(req, res, next) {
  res.send(req.headers)
});

module.exports = router;
