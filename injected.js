<script src="/socket.io/socket.io.js"></script>
<script src="//cdnjs.cloudflare.com/ajax/libs/jquery-url-parser/2.2.1/purl.min.js"></script>
<script>
  var socket = io.connect('http://localhost:3000');
  socket.on('change', function() {
    window.location.reload();
  });
</script>
