import 'package:flutter/foundation.dart'; // for ValueNotifier

class Translations {
  /// The current language, stored as a ValueNotifier.
  /// Changing this value will notify all listeners so that your UI can rebuild.
  static ValueNotifier<String> currentLanguage = ValueNotifier('German');

  /// The localized values for each supported language.
  static final Map<String, Map<String, String>> _localizedValues = {
    'English': {
      'orRegisterWithGoogle': 'Or register with Google:',
      'pleaseEnterValidEmail': 'Please enter a valid email address.',
      'emailAlreadyInUse':
          'This email is already in use. Please use a different email address.',
      'registrationSuccessful':
          'Registration Successful! A verification email has been sent. Please verify your email.',
      'error': 'Error',
      'googleSignInSuccessful': 'Google Sign-In Successful! Welcome!',
      'googleSignInError': 'Google Sign-In Error: %{error}',
      'googleUser': 'Google User',
      'alreadyHaveAccountSignIn': 'Already have an account? Sign In',

      'signInRegister': 'Sign In / Register',
      'signIn': 'Sign In',
      'register': 'Register',
      'signOut': 'Sign Out',
      'errorLoadingMenus': 'Error loading menus',
      'errorLoadingBillOrders': 'Error loading Bill Orders',
      'noDish': 'No Dish',
      'noHotel': 'No Hotel',
      'price': 'Price',
      'orderNow': 'Order Now',
      'myOrder': 'My Order',

      // NEW KEYS for Sign-In Dialog
      'enterYourEmail': 'Enter your email',
      'enterYourPassword': 'Enter your password',
      'signInWithGoogle': 'Sign in with Google',
      'cancel': 'Cancel',
      'incorrectUserOrPassword': 'Incorrect user or password',
      'signInSuccessful': 'Sign In Successful!',
      'forgotPassword': 'Forgot Password?',
      'dontHaveAccountSignup': 'Don\'t have an account? Signup',

      // MenuPage
      'whatsappError': 'Could not launch WhatsApp',
      'addedToChat': 'Added %{quantity} x %{dishName} to chat',
      'errorLoadingChat': 'Error loading chat items.',
      'yourChat': 'Your Chat',
      'yourChatEmpty': 'Your chat is empty.',
      'total': 'Total',
      'remove': 'Remove',
      'add': 'Add',
      'noMenuItemsFound': 'No menu items found',
      'errorLoadingMenuItems': 'Error loading menu items',
      'menu': 'Menu',
      'addToChat': 'Add to Chat',
      'dish': 'Dish',
      'cart': 'Cart',
      'filterByDish': 'Filter by Dish',
      'clearFilters': 'Clear Filters',

      // CheckoutPage
      'userNotAuthenticated': 'User not authenticated.',
      'selectShippingAddressFirst':
          'Please add/select a shipping address first!',
      'errorGeneratingOrderID': 'Error generating order ID. Please try again.',
      'orderPlaced': 'Order placed successfully!',
      'errorPlacingOrder': 'Failed to place the order. Please try again.',
      'billDetails': 'Bill Details',
      'hotel': 'Hotel',
      'address': 'Address',
      'loadingOrNotFound': 'Loading or not found',
      'shippingAddress': 'Shipping Address',
      'addAddress': 'Add Address',
      'change': 'Change',
      'noShippingAddressFound': 'No shipping address found.',
      'yourItems': 'Your Items',
      'noItemsInCart': 'No items in the cart.',
      'qty': 'Qty',
      'paymentMethod': 'Payment Method',
      'card': 'Card',
      'cashOnDelivery': 'Cash on Delivery',
      'confirmPayment': 'Confirm Payment',

      // NEW KEYS for BillOrdersWidget
      'orderNew': 'Order New',
      'kitchen': 'Kitchen',
      'onTheWay': 'On the way',
      'delivered': 'Delivered',
      'cancel': 'Cancel',
      'noOrdersInCategory': 'No orders in this category.',
      'timeLeft': 'Time Left:',
      'customer': 'Customer',
      'deliveryTime': 'Delivery Time',
      'accept': 'Accept',
      'pleaseSelectAnOrder': 'Please select an order',
      'orderID': 'Order ID',
      'timestamp': 'Timestamp',
      'hotelName': 'Hotel Name',
      'hotelAddress': 'Hotel Address',
      'phone': 'Phone',
      'cartItems': 'Cart Items',
      'quantity': 'Quantity',
      'scanOrderID': 'Scan Order ID',

      // NEW KEYS for PDF
      'companyName': 'Quickrun GmbH',
      'item': 'Item',
      'pay': 'Pay',
      'scan': 'Scan',
      'qrCode': 'QR Code',
      'qrCodeInstructions':
          'Scan the QR code to get the complete customer data.',

      // NEW KEYS for DetailsPage
      'billOrders': 'Bill Orders',
      'hotelDetails': 'Hotel Details',
      'orderHistory': 'Order History',
      'details': 'Details',
      'noDetailsFoundFor': 'No details found for',

      // NEW KEYS for CartPage
      'cartEmpty': 'Your cart is empty',
      'errorLoadingCartItems': 'Error loading cart items',
      'yourCart': 'Your Cart',
      'shopClosed': 'Shop Closed',
      'shopClosedMessage': 'Please come again during opening hours.',
      'showCart': 'Show Cart',
    },
    'German': {
      'orRegisterWithGoogle': 'Oder registriere dich mit Google:',
      'pleaseEnterValidEmail':
          'Bitte geben Sie eine gültige E-Mail-Adresse ein.',
      'emailAlreadyInUse':
          'Diese E-Mail wird bereits verwendet. Bitte verwenden Sie eine andere E-Mail-Adresse.',
      'registrationSuccessful':
          'Registrierung erfolgreich! Eine Bestätigungs-E-Mail wurde gesendet. Bitte bestätigen Sie Ihre E-Mail.',
      'error': 'Fehler',
      'googleSignInSuccessful': 'Google-Anmeldung erfolgreich! Willkommen!',
      'googleSignInError': 'Google-Anmeldung Fehler: %{error}',
      'googleUser': 'Google Benutzer',
      'alreadyHaveAccountSignIn': 'Haben Sie bereits ein Konto? Anmelden',

      'signInRegister': 'Anmelden / Registrieren',
      'signIn': 'Anmelden',
      'register': 'Registrieren',
      'signOut': 'Abmelden',
      'errorLoadingMenus': 'Fehler beim Laden der Menüs',
      'errorLoadingBillOrders': 'Fehler beim Laden der Bestellungen',
      'noDish': 'Kein Gericht',
      'noHotel': 'Kein Hotel',
      'price': 'Preis',
      'orderNow': 'Jetzt bestellen',
      'myOrder': 'Meine Bestellung',

      // NEW KEYS for Sign-In Dialog
      'enterYourEmail': 'Geben Sie Ihre E-Mail ein',
      'enterYourPassword': 'Geben Sie Ihr Passwort ein',
      'signInWithGoogle': 'Mit Google anmelden',
      'cancel': 'Abbrechen',
      'incorrectUserOrPassword': 'Falscher Benutzer oder falsches Passwort',
      'signInSuccessful': 'Anmeldung erfolgreich!',
      'forgotPassword': 'Passwort vergessen?',
      'dontHaveAccountSignup': 'Noch kein Konto? Registrieren',

      // MenuPage
      'whatsappError': 'WhatsApp konnte nicht geöffnet werden',
      'addedToChat': 'Hinzugefügt %{quantity} x %{dishName} zum Chat',
      'errorLoadingChat': 'Fehler beim Laden der Chat-Artikel.',
      'yourChat': 'Ihr Chat',
      'yourChatEmpty': 'Ihr Chat ist leer.',
      'total': 'Gesamt',
      'remove': 'Entfernen',
      'add': 'Hinzufügen',
      'noMenuItemsFound': 'Keine Menüelemente gefunden',
      'errorLoadingMenuItems': 'Fehler beim Laden der Menüelemente',
      'menu': 'Speisekarte',
      'addToChat': 'Zum Chat hinzufügen',
      'dish': 'Gericht',
      'cart': 'Warenkorb',
      'filterByDish': 'Nach Gericht filtern',
      'clearFilters': 'Filter löschen',

      // CheckoutPage
      'userNotAuthenticated': 'Benutzer nicht authentifiziert.',
      'selectShippingAddressFirst':
          'Bitte fügen Sie zuerst eine Lieferadresse hinzu/auswählen!',
      'errorGeneratingOrderID':
          'Fehler bei der Generierung der Bestellnummer. Bitte versuchen Sie es erneut.',
      'orderPlaced': 'Bestellung erfolgreich aufgegeben!',
      'errorPlacingOrder':
          'Fehler beim Aufgeben der Bestellung. Bitte versuchen Sie es erneut.',
      'billDetails': 'Rechnungsdetails',
      'hotel': 'Hotel',
      'address': 'Adresse',
      'loadingOrNotFound': 'Lädt oder nicht gefunden',
      'shippingAddress': 'Lieferadresse',
      'addAddress': 'Adresse hinzufügen',
      'change': 'Ändern',
      'noShippingAddressFound': 'Keine Lieferadresse gefunden.',
      'yourItems': 'Ihre Artikel',
      'noItemsInCart': 'Keine Artikel im Warenkorb.',
      'qty': 'Menge',
      'paymentMethod': 'Zahlungsmethode',
      'card': 'Karte',
      'cashOnDelivery': 'Nachnahme',
      'confirmPayment': 'Zahlung bestätigen',

      // NEW KEYS for BillOrdersWidget
      'orderNew': 'Neue Bestellung',
      'kitchen': 'Küche',
      'onTheWay': 'Unterwegs',
      'delivered': 'Geliefert',
      'cancel': 'Stornieren', // Reused key but different meaning
      'noOrdersInCategory': 'Keine Bestellungen in dieser Kategorie.',
      'timeLeft': 'Verbleibende Zeit:',
      'customer': 'Kunde',
      'deliveryTime': 'Lieferzeit',
      'accept': 'Akzeptieren',
      'pleaseSelectAnOrder': 'Bitte wählen Sie eine Bestellung aus',
      'orderID': 'Bestell-ID',
      'timestamp': 'Zeitstempel',
      'hotelName': 'Hotelname',
      'hotelAddress': 'Hoteladresse',
      'phone': 'Telefon',
      'cartItems': 'Warenkorb-Artikel',
      'quantity': 'Menge',
      'scanOrderID': 'Bestell-ID scannen',

      // NEW KEYS for PDF
      'companyName': 'Quickrun GmbH',
      'item': 'Artikel',
      'pay': 'Bezahlen',
      'scan': 'Scannen',
      'qrCode': 'QR-Code',
      'qrCodeInstructions':
          'Scannen Sie den QR-Code, um die vollständigen Kundendaten zu erhalten.',

      // NEW KEYS for DetailsPage
      'billOrders': 'Bestellungen',
      'hotelDetails': 'Hoteldetails',
      'orderHistory': 'Bestellverlauf',
      'details': 'Details',
      'noDetailsFoundFor': 'Keine Details gefunden für',

      // NEW KEYS for CartPage
      'cartEmpty': 'Ihr Warenkorb ist leer',
      'errorLoadingCartItems': 'Fehler beim Laden der Warenkorb-Artikel',
      'yourCart': 'Ihr Warenkorb',
      'shopClosed': 'Geschlossen',
      'shopClosedMessage':
          'Bitte kommen Sie während der Öffnungszeiten wieder.',
      'showCart': 'Warenkorb anzeigen',
    },
    'French': {
      // ... your other keys ...
      'orRegisterWithGoogle': 'Ou inscrivez-vous avec Google:',
      'pleaseEnterValidEmail': 'Veuillez entrer une adresse e-mail valide.',
      'emailAlreadyInUse':
          'Cet e-mail est déjà utilisé. Veuillez utiliser une autre adresse e-mail.',
      'registrationSuccessful':
          'Inscription réussie ! Un e-mail de vérification a été envoyé. Veuillez vérifier votre e-mail.',
      'error': 'Erreur',
      'googleSignInSuccessful': 'Connexion Google réussie ! Bienvenue !',
      'googleSignInError': 'Erreur de connexion Google : %{error}',
      'googleUser': 'Utilisateur Google',
      'alreadyHaveAccountSignIn': 'Vous avez déjà un compte ? Connectez-vous',
      'signInRegister': 'Se connecter / S\'inscrire',
      'signIn': 'Se connecter',
      'register': 'S\'inscrire',
      'signOut': 'Se déconnecter',
      'errorLoadingMenus': 'Erreur de chargement des menus',
      'errorLoadingBillOrders': 'Erreur lors du chargement des commandes',
      'noDish': 'Aucun plat',
      'noHotel': 'Aucun hôtel',
      'price': 'Prix',
      'orderNow': 'Commander maintenant',
      'myOrder': 'Ma commande',

      // NEW KEYS for Sign-In Dialog
      'enterYourEmail': 'Entrez votre e-mail',
      'enterYourPassword': 'Entrez votre mot de passe',
      'signInWithGoogle': 'Se connecter avec Google',
      'cancel': 'Annuler',
      'incorrectUserOrPassword': 'Nom d\'utilisateur ou mot de passe incorrect',
      'signInSuccessful': 'Connexion réussie!',
      'forgotPassword': 'Mot de passe oublié ?',
      'dontHaveAccountSignup': 'Vous n\'avez pas de compte? Inscrivez-vous',

      // MenuPage
      'whatsappError': 'Impossible de lancer WhatsApp',
      'addedToChat': 'Ajouté %{quantity} x %{dishName} au chat',
      'errorLoadingChat': 'Erreur de chargement des éléments du chat.',
      'yourChat': 'Votre Chat',
      'yourChatEmpty': 'Votre chat est vide.',
      'total': 'Total',
      'remove': 'Supprimer',
      'add': 'Ajouter',
      'noMenuItemsFound': 'Aucun élément de menu trouvé',
      'errorLoadingMenuItems': 'Erreur de chargement des éléments du menu',
      'menu': 'Menu',
      'addToChat': 'Ajouter au chat',
      'dish': 'Plat',
      'cart': 'Panier',
      'filterByDish': 'Filtrer par plat',
      'clearFilters': 'Effacer les filtres',

      // CheckoutPage
      'userNotAuthenticated': 'Utilisateur non authentifié.',
      'selectShippingAddressFirst':
          'Veuillez ajouter/sélectionner une adresse de livraison d\'abord !',
      'errorGeneratingOrderID':
          'Erreur lors de la génération de l\'ID de commande. Veuillez réessayer.',
      'orderPlaced': 'Commande passée avec succès !',
      'errorPlacingOrder': 'Échec de la commande. Veuillez réessayer.',
      'billDetails': 'Détails de la facture',
      'hotel': 'Hôtel',
      'address': 'Adresse',
      'loadingOrNotFound': 'Chargement ou introuvable',
      'shippingAddress': 'Adresse de livraison',
      'addAddress': 'Ajouter une adresse',
      'change': 'Changer',
      'noShippingAddressFound': 'Aucune adresse de livraison trouvée.',
      'yourItems': 'Vos articles',
      'noItemsInCart': 'Aucun article dans le panier.',
      'qty': 'Qté',
      'paymentMethod': 'Méthode de paiement',
      'card': 'Carte',
      'cashOnDelivery': 'Paiement à la livraison',
      'confirmPayment': 'Confirmer le paiement',

      // NEW KEYS for BillOrdersWidget
      'orderNew': 'Nouvelle commande',
      'kitchen': 'Cuisine',
      'onTheWay': 'En route',
      'delivered': 'Livré',
      'cancel': 'Annuler', // Reused key but different meaning
      'noOrdersInCategory': 'Aucune commande dans cette catégorie.',
      'timeLeft': 'Temps restant :',
      'customer': 'Client',
      'deliveryTime': 'Heure de livraison',
      'accept': 'Accepter',
      'pleaseSelectAnOrder': 'Veuillez sélectionner une commande',
      'orderID': 'ID de commande',
      'timestamp': 'Horodatage',
      'hotelName': 'Nom de l\'hôtel',
      'hotelAddress': 'Adresse de l\'hôtel',
      'phone': 'Téléphone',
      'cartItems': 'Articles du panier',
      'quantity': 'Quantité',
      'scanOrderID': 'Scanner l\'ID de commande',

      // NEW KEYS for PDF
      'companyName': 'Quickrun GmbH',
      'item': 'Article',
      'pay': 'Payer',
      'scan': 'Scanner',
      'qrCode': 'QR Code',
      'qrCodeInstructions':
          'Scannez le QR code pour obtenir l\'ensemble des informations du client.',

      // NEW KEYS for DetailsPage
      'billOrders': 'Commandes',
      'hotelDetails': 'Détails de l\'hôtel',
      'orderHistory': 'Historique des commandes',
      'details': 'Détails',
      'noDetailsFoundFor': 'Aucun détail trouvé pour',

      // NEW KEYS for CartPage
      'cartEmpty': 'Votre panier est vide',
      'errorLoadingCartItems':
          'Erreur lors du chargement des articles du panier',
      'yourCart': 'Votre panier',
      'shopClosed': 'Boutique fermée',
      'shopClosedMessage': 'Veuillez revenir pendant les heures d\'ouverture.',
      'showCart': 'Afficher le panier',
    },
  };

  /// Sets the current language to the given [language].
  static void setLanguage(String language) {
    currentLanguage.value = language;
  }

  /// Retrieves the translated text for the given [key].
  /// If [params] are provided, replaces placeholders formatted as "%{param}" with their values.
  static String text(String key, {Map<String, dynamic>? params}) {
    final lang = currentLanguage.value;
    // Look up the key in the current language; if missing, fall back to English; if still missing, return the key.
    String translated = _localizedValues[lang]?[key] ??
        _localizedValues['English']?[key] ??
        key;

    if (params != null) {
      params.forEach((paramKey, value) {
        translated = translated.replaceAll('%{$paramKey}', value.toString());
      });
    }
    return translated;
  }
}
