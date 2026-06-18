import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/weather_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialWeather();
  }

  Future<void> _fetchInitialWeather() async {
    setState(() => _isLoading = true);
    
    // Fetch the user's default city from MongoDB
    final String? userCity = await _authService.getUserLocation();
    
    if (userCity != null && userCity.isNotEmpty) {
      final data = await _weatherService.getWeather(userCity);
      if (mounted) {
        setState(() {
          _weatherData = data;
        });
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchWeather() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    FocusScope.of(context).unfocus(); // Dismiss keyboard

    final data = await _weatherService.getWeather(query);
    
    if (mounted) {
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch weather data. Please try again.')),
        );
      } else {
        setState(() {
          _weatherData = data;
        });
      }
      setState(() => _isSearching = false);
    }
  }

  void _logout(BuildContext context) async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Weather App', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.blue.shade600, Colors.blue.shade800],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _weatherData == null 
                    ? _buildErrorView() 
                    : _buildWeatherCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search city...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Colors.white),
              ),
              onSubmitted: (_) => _searchWeather(),
            ),
          ),
          if (_isSearching)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          else
            ElevatedButton(
              onPressed: _searchWeather,
              style: ElevatedButton.styleFrom(
                primary: Colors.blue.shade700,
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Search'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('🌤️', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'No Weather Data',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 8),
            Text(
              'Could not load weather for your default location.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final current = _weatherData!['current'];
    final location = _weatherData!['location'];
    
    // WeatherAPI returns URLs like "//cdn.weatherapi.com/...". We need to add "https:"
    String iconUrl = current['condition']['icon'];
    if (iconUrl.startsWith('//')) {
      iconUrl = 'https:$iconUrl';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${location['name']}, ${location['country']}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  location['localtime'],
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                
                Image.network(iconUrl, width: 100, height: 100, fit: BoxFit.cover),
                
                Text(
                  current['condition']['text'],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                
                const SizedBox(height: 32),
                
                // Metrics Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildMetricCard(Icons.thermostat, 'Temperature', '${current['temp_c']}°C', Colors.blue),
                    _buildMetricCard(Icons.opacity, 'Humidity', '${current['humidity']}%', Colors.green),
                    _buildMetricCard(Icons.air, 'Wind Speed', '${current['wind_kph']} km/h', Colors.orange),
                    _buildMetricCard(Icons.visibility, 'Visibility', '${current['vis_km']} km', Colors.purple),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(thickness: 1.5),
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Feels like: ', style: TextStyle(color: Colors.black54, fontSize: 16)),
                    Text('${current['feelslike_c']}°C', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('|', style: TextStyle(color: Colors.black26, fontSize: 18)),
                    ),
                    const Text('UV Index: ', style: TextStyle(color: Colors.black54, fontSize: 16)),
                    Text('${current['uv']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildMetricCard(IconData icon, String title, String value, MaterialColor color) {
    return Container(
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.shade600, size: 28),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
        ],
      ),
    );
  }
}
