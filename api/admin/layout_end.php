  </div><!-- /content -->
</div><!-- /main -->
<script>
function toggleSidebar(){document.querySelector('.sidebar')?.classList.toggle('open');document.getElementById('sidebarOverlay')?.classList.toggle('show');}
function closeSidebar(){document.querySelector('.sidebar')?.classList.remove('open');document.getElementById('sidebarOverlay')?.classList.remove('show');}
document.querySelectorAll('.sidebar .nav-item').forEach(function(a){a.addEventListener('click',function(){if(window.innerWidth<=900)closeSidebar();});});
</script>
</body>
</html>
