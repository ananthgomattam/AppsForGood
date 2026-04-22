import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/medication.dart';
import '../database/database_helper.dart';

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────

class _SideEffect {
  final String name;
  final String description;
  final bool urgent; // true = call 911 / seek emergency care

  const _SideEffect({
    required this.name,
    required this.description,
    required this.urgent,
  });
}

class _MedSafetyInfo {
  final String name;
  final List<String> foodInteractions;
  final List<_SideEffect> sideEffects;
  final String interactionsUrl;

  const _MedSafetyInfo({
    required this.name,
    required this.foodInteractions,
    required this.sideEffects,
    required this.interactionsUrl,
  });
}

// ─────────────────────────────────────────────
// Safety data catalogue
// ─────────────────────────────────────────────

const List<_MedSafetyInfo> _safetyData = [
  _MedSafetyInfo(
    name: 'Acetazolamide',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately. Signs include hives, swelling of the face, lips, tongue, or throat, and trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Aplastic anemia',
        description:
            'Go to an emergency room now. Signs include extreme weakness, fatigue, dizziness, headache, trouble breathing, and unusual bleeding or bruising.',
        urgent: true,
      ),
      _SideEffect(
        name: 'High acid level (metabolic acidosis)',
        description:
            'Call your doctor or go to urgent care. Signs include trouble breathing, weakness, fatigue, confusion, headache, irregular heartbeat, nausea, or vomiting.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Infection',
        description:
            'Contact your doctor promptly if you develop fever, chills, or signs of infection.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Kidney stones',
        description:
            'Call your doctor. Signs include pain in the lower back or sides, blood in urine, or pain when urinating.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Liver injury',
        description:
            'Seek urgent medical attention. Signs include upper belly pain, loss of appetite, nausea, light-colored stool, dark urine, yellowing skin or eyes, weakness, or fatigue.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Low potassium',
        description:
            'Contact your doctor. Signs include muscle cramps, irregular or fast heartbeat, constipation, or weakness.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Skin blistering or loosening',
        description:
            'Seek emergency care immediately. This is a serious skin reaction including inside the mouth.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Blurry vision',
        description: 'Common side effect. Let your doctor know at your next visit.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Change in taste',
        description: 'Common and usually mild. Mention it to your doctor if it bothers you.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of appetite',
        description: 'Common side effect. Try eating smaller, more frequent meals.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Tingling in hands or feet',
        description: 'Common and often temporary. Let your doctor know if it worsens.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/acetazolamide-index.html',
  ),
  _MedSafetyInfo(
    name: 'Brivaracetam',
    foodInteractions: ['Alcohol'],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately. Signs include skin rash, itching, hives, or swelling of the face, lips, tongue, or throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood or behavior changes / suicidal thoughts',
        description:
            'Call 911 or go to the emergency room if there are thoughts of suicide or self-harm. Call your doctor right away for anxiety, hallucinations, hostility, or worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care immediately for redness, blistering, peeling, or loosening of skin including inside the mouth.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness',
        description: 'Common side effect. Avoid driving until you know how this medication affects you.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Drowsiness',
        description: 'Common side effect. Avoid alcohol and driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Fatigue',
        description: 'Common and usually manageable. Rest when needed.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of balance or coordination',
        description: 'Common. Use caution with stairs and driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Nausea / vomiting',
        description: 'Common side effect. Try taking with food.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Uncontrollable eye movements',
        description: 'Mention this to your doctor — it may indicate dose adjustment is needed.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/brivaracetam-index.html',
  ),
  _MedSafetyInfo(
    name: 'Cannabidiol',
    foodInteractions: ['Alcohol', 'Grapefruit'],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately. Signs include skin rash, hives, or swelling of the face, lips, tongue, or throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Liver problems',
        description:
            'Contact your doctor promptly. Signs include loss of appetite, nausea, vomiting, or yellowing of the skin or eyes.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 immediately if there are thoughts of suicide or self-harm. Call your doctor for agitation or worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Drowsiness',
        description: 'Common. Avoid driving or operating heavy machinery.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Diarrhea',
        description: 'Common. Stay hydrated and let your doctor know if it persists.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Fatigue',
        description: 'Common side effect. Rest as needed.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Decreased appetite',
        description: 'Common. Try eating small, frequent meals.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/cannabidiol-index.html',
  ),
  _MedSafetyInfo(
    name: 'Carbamazepine',
    foodInteractions: ['Grapefruit'],
    sideEffects: [
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care immediately for blistering, peeling, or serious rash.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately for swelling or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Low blood cell counts',
        description:
            'Call your doctor right away. Signs include fever, sore throat, or unusual bleeding.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide or self-harm. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving until you know how this medication affects you.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Nausea / vomiting',
        description: 'Common. Try taking with food.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/carbamazepine-index.html',
  ),
  _MedSafetyInfo(
    name: 'Cenobamate',
    foodInteractions: ['Alcohol'],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately for rash or swelling.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Heart rhythm changes',
        description:
            'Call 911 or go to the ER immediately for irregular heartbeat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Liver problems',
        description:
            'Contact your doctor promptly for yellowing skin or eyes.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide or self-harm. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Drowsiness / dizziness',
        description: 'Common. Avoid driving and alcohol.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Fatigue / headache',
        description: 'Common side effects. Rest and stay hydrated.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/cenobamate-index.html',
  ),
  _MedSafetyInfo(
    name: 'Clobazam',
    foodInteractions: ['Alcohol'],
    sideEffects: [
      _SideEffect(
        name: 'Breathing problems',
        description:
            'Call 911 immediately for slow, shallow, or difficult breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe drowsiness or sedation',
        description:
            'Seek medical attention immediately if you cannot be roused or stay awake.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide or self-harm. Contact your doctor for aggression or worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Sleepiness / drooling',
        description: 'Common side effects.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Constipation',
        description: 'Common. Stay hydrated and increase dietary fiber.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Fever',
        description: 'If mild, monitor. If persistent or high, contact your doctor.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/clobazam.html',
  ),
  _MedSafetyInfo(
    name: 'Clonazepam',
    foodInteractions: ['Alcohol'],
    sideEffects: [
      _SideEffect(
        name: 'Breathing difficulty',
        description:
            'Call 911 immediately for slow or difficult breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe sedation',
        description:
            'Seek emergency care immediately if unable to stay awake.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide or self-harm. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Drowsiness / dizziness',
        description: 'Common. Avoid driving and alcohol.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Coordination problems',
        description: 'Common. Use caution on stairs and with driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Fatigue',
        description: 'Common. Rest as needed.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/clonazepam-index.html',
  ),
  _MedSafetyInfo(
    name: 'Eslicarbazepine',
    foodInteractions: ['Alcohol'],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately for hives, swelling of face/lips/tongue/throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Infection',
        description:
            'Contact your doctor for fever, chills, cough, or sore throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Low sodium level',
        description:
            'Call your doctor. Signs include muscle weakness, fatigue, dizziness, headache, or confusion.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Rash with fever and swollen lymph nodes',
        description:
            'Seek urgent medical care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care for redness, blistering, or peeling of skin.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Double vision',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Headache / nausea',
        description: 'Common. Take with food if nausea occurs.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Memory or speech difficulty',
        description: 'Common. Let your doctor know if it affects daily life.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/eslicarbazepine-index.html',
  ),
  _MedSafetyInfo(
    name: 'Ethosuximide',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Kidney injury',
        description:
            'Contact your doctor promptly. Signs include decreased urine or swelling of ankles, hands, or feet.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Liver injury',
        description:
            'Seek urgent care. Signs include right upper belly pain, dark urine, yellowing skin or eyes.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Lupus-like syndrome',
        description:
            'Contact your doctor. Signs include joint pain, butterfly-shaped face rash, rashes worsening in sun, fever.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care for blistering or peeling skin.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide or self-harm.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Unusual bruising or bleeding',
        description:
            'Contact your doctor promptly.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Diarrhea / nausea',
        description: 'Common. Take with food.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Dizziness / fatigue',
        description: 'Common. Rest as needed.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Hiccups',
        description: 'Unusual but common with this medication. Mention to your doctor.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of appetite / weight loss',
        description: 'Common. Try small frequent meals.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/ethosuximide-index.html',
  ),
  _MedSafetyInfo(
    name: 'Everolimus',
    foodInteractions: ['Grapefruit'],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction / angioedema',
        description:
            'Seek emergency care immediately for swelling, hives, or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Breathing problems',
        description:
            'Call your doctor or go to urgent care for dry cough or shortness of breath.',
        urgent: true,
      ),
      _SideEffect(
        name: 'High blood sugar',
        description:
            'Contact your doctor. Signs include increased thirst, frequent urination, unusual fatigue, or blurry vision.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Infection',
        description:
            'Contact your doctor for fever, chills, sore throat, or wounds that won\'t heal.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Kidney injury',
        description:
            'Contact your doctor for decreased urine or swelling of ankles, hands, or feet.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Hemolytic uremic syndrome (HUS)',
        description:
            'Seek emergency care immediately for stomach pain, bloody diarrhea, pale skin, or decreased urine.',
        urgent: true,
      ),
      _SideEffect(
        name: 'TTP (blood clotting disorder)',
        description:
            'Seek emergency care immediately for purple skin spots, pale skin, confusion, vision changes, or irregular heartbeat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Constipation / diarrhea',
        description: 'Common. Stay hydrated.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Headache / stomach pain',
        description: 'Common. Take with food if stomach upset occurs.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Swelling of ankles, hands, or feet',
        description: 'Common. Elevate feet when resting and mention to your doctor.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/everolimus-index.html',
  ),
  _MedSafetyInfo(
    name: 'Fenfluramine',
    foodInteractions: ['Alcohol'],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Heart valve disease',
        description:
            'Seek urgent medical care for shortness of breath, chest pain, fatigue, dizziness, fast or irregular heartbeat, or sudden weight gain.',
        urgent: true,
      ),
      _SideEffect(
        name: 'High blood pressure',
        description:
            'Monitor regularly. Contact your doctor if blood pressure rises significantly.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Serotonin syndrome',
        description:
            'Call 911 immediately for irritability, confusion, fast heartbeat, muscle stiffness, twitching, sweating, high fever, or seizure.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Pulmonary arterial hypertension',
        description:
            'Seek urgent care for shortness of breath, swelling of ankles/hands/feet, dizziness, chest pain, or blue lips/skin.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Sudden eye pain or vision change',
        description:
            'Seek urgent care immediately for sudden eye pain, blurry vision, or vision loss.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Constipation / diarrhea',
        description: 'Common. Stay hydrated.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of appetite / weight loss',
        description: 'Common. Eat regularly even if not hungry.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/fenfluramine-index.html',
  ),
  _MedSafetyInfo(
    name: 'Gabapentin',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction / angioedema',
        description:
            'Seek emergency care immediately for swelling, hives, or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Rash with fever and swollen lymph nodes',
        description:
            'Seek urgent medical care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Trouble breathing',
        description:
            'Call 911 immediately for slow or difficult breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Behavior changes in children',
        description:
            'Contact your doctor if your child shows trouble concentrating, hostility, or unusual restlessness.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Nausea / vomiting',
        description: 'Common. Take with food.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Swelling of ankles, hands, or feet',
        description: 'Common. Elevate feet and mention to your doctor.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/gabapentin-index.html',
  ),
  _MedSafetyInfo(
    name: 'Lacosamide',
    foodInteractions: ['Alcohol'],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Heart rhythm changes',
        description:
            'Call 911 immediately for fast or irregular heartbeat, dizziness, chest pain, or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Rash with fever and swollen lymph nodes',
        description:
            'Seek urgent medical care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Double vision',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Headache / nausea',
        description: 'Common. Take with food.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of balance or coordination',
        description: 'Common. Use caution with stairs.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/lacosamide-index.html',
  ),
  _MedSafetyInfo(
    name: 'Lamotrigine',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately for hives, swelling, or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Meningitis signs',
        description:
            'Call 911 immediately for fever, neck stiffness, sensitivity to light, headache, nausea, vomiting, or confusion.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care immediately for redness, blistering, or peeling skin including inside the mouth.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Heart rhythm changes',
        description:
            'Call 911 immediately for fast or irregular heartbeat, dizziness, chest pain, or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Infection',
        description:
            'Contact your doctor for fever, chills, cough, or sore throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Low red blood cell level',
        description:
            'Contact your doctor for unusual weakness, fatigue, dizziness, headache, or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Unusual bruising or bleeding',
        description:
            'Contact your doctor promptly.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Headache / nausea',
        description: 'Common. Take with food.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Diarrhea / stomach pain',
        description: 'Common. Stay hydrated.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Tremors or shaking',
        description: 'Common. Let your doctor know if it affects daily tasks.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/lamotrigine-index.html',
  ),
  _MedSafetyInfo(
    name: 'Levetiracetam',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction / angioedema',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Infection',
        description:
            'Contact your doctor for fever, chills, or sore throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Low red blood cell level',
        description:
            'Contact your doctor for unusual weakness, fatigue, dizziness, headache, or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood or behavior changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for anxiety, hallucinations, hostility, or worsening mood.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care for redness, blistering, or swelling over hands and feet.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Unusual bruising or bleeding',
        description:
            'Contact your doctor promptly.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Fatigue / irritability',
        description: 'Common. Rest when needed and let your doctor know if it\'s affecting quality of life.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of appetite',
        description: 'Common. Try eating small frequent meals.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/levetiracetam-index.html',
  ),
  _MedSafetyInfo(
    name: 'Oxcarbazepine',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Infection',
        description:
            'Contact your doctor for fever, chills, cough, or sore throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Low sodium level',
        description:
            'Call your doctor. Signs include muscle weakness, fatigue, dizziness, headache, or confusion.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care for redness, blistering, or peeling skin.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Seizures (new or worsening)',
        description:
            'Contact your doctor immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Double vision',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Headache / nausea',
        description: 'Common. Take with food.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Memory or speech difficulty',
        description: 'Common. Let your doctor know if it affects daily life.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/oxcarbazepine-index.html',
  ),
  _MedSafetyInfo(
    name: 'Perampanel',
    foodInteractions: ['Alcohol', 'St. John\'s Wort'],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood or behavior changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for hostility, hallucinations, or worsening mood.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Rash with fever and swollen lymph nodes',
        description:
            'Seek urgent medical care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving and alcohol.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Fatigue / headache',
        description: 'Common. Rest as needed.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Irritability',
        description: 'Common. Let your doctor know if it affects relationships or daily life.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Nausea / weight gain',
        description: 'Common. Watch diet and exercise regularly.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/perampanel-index.html',
  ),
  _MedSafetyInfo(
    name: 'Phenobarbital',
    foodInteractions: ['Alcohol'],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'CNS depression (severe breathing issues)',
        description:
            'Call 911 immediately for slow or shallow breathing, feeling faint, or inability to stay awake.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving and alcohol.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Headache / nausea',
        description: 'Common. Take with food.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/phenobarbital-index.html',
  ),
  _MedSafetyInfo(
    name: 'Phenytoin',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'High blood sugar',
        description:
            'Contact your doctor for increased thirst, frequent urination, unusual fatigue, or blurry vision.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Infection',
        description:
            'Contact your doctor for fever, chills, or sore throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Liver injury',
        description:
            'Seek urgent care for right upper belly pain, dark urine, or yellowing skin or eyes.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Phenytoin toxicity',
        description:
            'Call your doctor immediately for uncontrollable eye movements, loss of balance, trouble speaking, or unusual fatigue.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care for redness, blistering, or peeling skin.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Slow heartbeat',
        description:
            'Seek emergency care for dizziness, fainting, confusion, or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Unusual bruising or bleeding',
        description:
            'Contact your doctor promptly.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Headache',
        description: 'Common. Rest and stay hydrated.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Memory or speech difficulty',
        description: 'Common. Let your doctor know if it affects daily life.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/phenytoin-index.html',
  ),
  _MedSafetyInfo(
    name: 'Pregabalin',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction / angioedema',
        description:
            'Seek emergency care immediately for swelling, hives, or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Muscle injury (rhabdomyolysis)',
        description:
            'Contact your doctor for unusual weakness, muscle pain, or dark urine.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Trouble breathing',
        description:
            'Call 911 immediately for slow or difficult breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Unusual bruising or bleeding',
        description:
            'Contact your doctor promptly.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Behavior changes in children',
        description:
            'Contact your doctor for trouble concentrating, hostility, or unusual restlessness.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Blurry vision',
        description: 'Common. Avoid driving if affected.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Dry mouth',
        description: 'Common. Stay hydrated.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Swelling of ankles, hands, or feet',
        description: 'Common. Elevate feet when resting.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Weight gain',
        description: 'Common. Maintain a balanced diet and exercise regularly.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/pregabalin-index.html',
  ),
  _MedSafetyInfo(
    name: 'Primidone',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'CNS depression (severe breathing issues)',
        description:
            'Call 911 immediately for slow or shallow breathing or inability to stay awake.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of balance or coordination',
        description: 'Common. Use caution on stairs.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Nausea',
        description: 'Common. Take with food.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/primidone.html',
  ),
  _MedSafetyInfo(
    name: 'Rufinamide',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Infection',
        description:
            'Contact your doctor for fever, chills, or sore throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Rash with fever and swollen lymph nodes',
        description:
            'Seek urgent medical care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Fatigue / headache',
        description: 'Common. Rest as needed.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Nausea',
        description: 'Common. Take with food.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/rufinamide.html',
  ),
  _MedSafetyInfo(
    name: 'Stiripentol',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Infection',
        description:
            'Contact your doctor for fever, chills, or sore throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Unusual bruising or bleeding',
        description:
            'Contact your doctor promptly.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Agitation / irritability / restlessness',
        description: 'Common. Let your doctor know if it\'s affecting daily life.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of appetite / weight loss',
        description: 'Common. Eat regular meals even if not hungry.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of balance or coordination',
        description: 'Common. Use caution with stairs.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Low muscle tone',
        description: 'Common. Mention to your doctor if worsening.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Nausea / tremors',
        description: 'Common. Take with food and let your doctor know.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Trouble sleeping / speaking',
        description: 'Common. Mention to your doctor at your next visit.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/stiripentol-index.html',
  ),
  _MedSafetyInfo(
    name: 'Tiagabine',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'New or worsening seizures',
        description:
            'Contact your doctor immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care for redness, blistering, or peeling skin.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Vision changes',
        description:
            'Contact your doctor for any changes in vision.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Headache',
        description: 'Common. Rest and stay hydrated.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Memory or speech difficulty',
        description: 'Common. Let your doctor know if it affects daily life.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Tremors or shaking',
        description: 'Common. Mention to your doctor.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Unusual weakness / fatigue',
        description: 'Common. Rest as needed.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/tiagabine-index.html',
  ),
  _MedSafetyInfo(
    name: 'Topiramate',
    foodInteractions: ['Alcohol'],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'High acid level (metabolic acidosis)',
        description:
            'Call your doctor or go to urgent care for trouble breathing, weakness, confusion, headache, fast or irregular heartbeat, nausea, or vomiting.',
        urgent: true,
      ),
      _SideEffect(
        name: 'High ammonia level',
        description:
            'Seek urgent care for unusual weakness, confusion, loss of appetite, nausea, vomiting, or seizures.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Fever that won\'t go away / decreased sweating',
        description:
            'Seek urgent care — this can be dangerous, especially in children.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Kidney stones',
        description:
            'Contact your doctor for blood in urine, pain passing urine, or pain in lower back or sides.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care for redness, blistering, or peeling skin.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Sudden eye pain or vision change',
        description:
            'Seek urgent care immediately for sudden eye pain, blurry vision, halos around lights, or vision loss.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Burning or tingling in hands or feet',
        description: 'Common. Let your doctor know if it worsens.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Fatigue',
        description: 'Common. Rest as needed.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of appetite / weight loss',
        description: 'Common. Eat regular meals.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Memory or speech difficulty',
        description: 'Common. Let your doctor know if it affects daily life.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/topiramate-index.html',
  ),
  _MedSafetyInfo(
    name: 'Valproic Acid',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction / angioedema',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'High ammonia level',
        description:
            'Seek urgent care for unusual weakness, confusion, loss of appetite, nausea, vomiting, or seizures.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Liver injury',
        description:
            'Seek urgent care for right upper belly pain, dark urine, or yellowing skin or eyes.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Low body temperature with drowsiness or confusion',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Pancreatitis',
        description:
            'Seek emergency care for severe stomach pain that spreads to your back, worsens after eating, or is accompanied by fever, nausea, or vomiting.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care for redness, blistering, or peeling skin.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Unusual bruising or bleeding',
        description:
            'Contact your doctor promptly.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Vision changes',
        description: 'Common. Let your doctor know.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Hair loss',
        description: 'Common. Usually temporary. Biotin supplements may help — ask your doctor.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Headache / nausea',
        description: 'Common. Take with food.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Tremors or shaking',
        description: 'Common. Let your doctor know if it affects daily tasks.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Weight gain',
        description: 'Common. Maintain a balanced diet and exercise.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/valproic-acid-index.html',
  ),
  _MedSafetyInfo(
    name: 'Sodium valproate',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction / angioedema',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Liver injury',
        description:
            'Seek urgent care for right upper belly pain, dark urine, or yellowing skin or eyes.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Pancreatitis',
        description:
            'Seek emergency care for severe stomach pain that spreads to your back or worsens after eating.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Unusual bruising or bleeding',
        description:
            'Contact your doctor promptly.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Hair loss',
        description: 'Common. Usually temporary.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Nausea / tremors',
        description: 'Common. Take with food.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Weight gain',
        description: 'Common. Maintain a balanced diet.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/valproic-acid-index.html',
  ),
  _MedSafetyInfo(
    name: 'Vigabatrin',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Vision changes',
        description:
            'Seek urgent care for blurry vision, halos around lights, or vision loss.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Low red blood cell level',
        description:
            'Contact your doctor for unusual weakness, fatigue, dizziness, headache, or trouble breathing.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Pain, tingling, or numbness in hands or feet',
        description:
            'Contact your doctor if this develops.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Fatigue',
        description: 'Common. Rest as needed.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of balance or coordination',
        description: 'Common. Use caution on stairs.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Swelling of ankles, hands, or feet',
        description: 'Common. Elevate feet when resting.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Tremors / weight gain',
        description: 'Common. Mention at your next visit.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/vigabatrin-index.html',
  ),
  _MedSafetyInfo(
    name: 'Zonisamide',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description:
            'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Aplastic anemia',
        description:
            'Seek emergency care for unusual weakness, fatigue, dizziness, trouble breathing, or unusual bleeding or bruising.',
        urgent: true,
      ),
      _SideEffect(
        name: 'CNS depression (severe breathing issues)',
        description:
            'Call 911 immediately for slow or shallow breathing or inability to stay awake.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Fever that won\'t go away / decreased sweating',
        description:
            'Seek urgent care — this can be dangerous, especially in children.',
        urgent: true,
      ),
      _SideEffect(
        name: 'High acid level (metabolic acidosis)',
        description:
            'Call your doctor or go to urgent care for trouble breathing, weakness, confusion, headache, or irregular heartbeat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'High ammonia level',
        description:
            'Seek urgent care for unusual weakness, confusion, nausea, vomiting, or seizures.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Infection',
        description:
            'Contact your doctor for fever, chills, or sore throat.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Kidney stones',
        description:
            'Contact your doctor for blood in urine or pain in lower back or sides.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Severe skin reaction',
        description:
            'Seek emergency care for redness, blistering, or peeling skin.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Sudden eye pain or vision change',
        description:
            'Seek urgent care immediately for sudden eye pain, blurry vision, or vision loss.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood changes / suicidal thoughts',
        description:
            'Call 911 for thoughts of suicide. Contact your doctor for worsening depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Irritability',
        description: 'Common. Let your doctor know if it affects daily life.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Loss of appetite',
        description: 'Common. Eat regular meals.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Memory or speech difficulty',
        description: 'Common. Mention at your next visit.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/zonisamide-index.html',
  ),
  _MedSafetyInfo(
    name: 'Piracetam',
    foodInteractions: [],
    sideEffects: [
      _SideEffect(
        name: 'Allergic reaction',
        description: 'Seek emergency care immediately.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Mood or behavior changes',
        description: 'Contact your doctor if you notice unusual agitation, anxiety, or depression.',
        urgent: true,
      ),
      _SideEffect(
        name: 'Dizziness / drowsiness',
        description: 'Common. Avoid driving.',
        urgent: false,
      ),
      _SideEffect(
        name: 'Headache',
        description: 'Common. Stay hydrated and rest.',
        urgent: false,
      ),
    ],
    interactionsUrl: 'https://www.drugs.com/drug-interactions/piracetam.html',
  ),
];

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

class MedicationSafetyScreen extends StatefulWidget {
  const MedicationSafetyScreen({super.key});

  @override
  State<MedicationSafetyScreen> createState() => _MedicationSafetyScreenState();
}

class _MedicationSafetyScreenState extends State<MedicationSafetyScreen> {
  List<Medication> _myMedications = [];
  bool _loading = true;

  // Which medication card is expanded
  String? _expandedMed;

  // Which side effect tile is expanded within a medication
  final Map<String, String?> _expandedEffect = {};

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    try {
      final meds = await DatabaseHelper.instance.getAllMedications();
      if (!mounted) return;
      setState(() {
        _myMedications = meds;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Failed to load medications: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _myMedications = [];
        _loading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  _MedSafetyInfo? _safetyInfoFor(String name) {
    try {
      return _safetyData.firstWhere(
        (s) => s.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Safety'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myMedications.isEmpty
              ? _buildEmptyState(theme)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTopBanner(theme),
                    const SizedBox(height: 16),
                    ..._myMedications.map((med) => _buildMedCard(med, theme, colorScheme)),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No medications added yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add medications from the Medication tab to see safety information here.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tap a side effect below to find out if it needs urgent attention or if it\'s a common, manageable effect.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedCard(Medication med, ThemeData theme, ColorScheme colorScheme) {
    final info = _safetyInfoFor(med.name);
    final isExpanded = _expandedMed == med.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          InkWell(
            onTap: () {
              setState(() {
                _expandedMed = isExpanded ? null : med.name;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.medication, color: colorScheme.onPrimaryContainer, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${med.dosage} · ${med.frequencyCount}x per ${med.frequencyUnit}',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ──
          if (isExpanded) ...[
            if (info == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'No detailed safety information available for this medication.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                ),
              )
            else ...[
              // Food interaction warning
              if (info.foodInteractions.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.no_food_rounded,
                          size: 20, color: colorScheme.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Avoid while taking this medication:',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              info.foodInteractions.join(', '),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Side effects section label
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Text(
                  'Side effects — tap to learn more',
                  style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.outline),
                ),
              ),

              // Side effects list
              ...info.sideEffects.map((effect) {
                final isEffectExpanded = _expandedEffect[med.name] == effect.name;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: _SideEffectTile(
                    effect: effect,
                    isExpanded: isEffectExpanded,
                    onTap: () {
                      setState(() {
                        _expandedEffect[med.name] =
                            isEffectExpanded ? null : effect.name;
                      });
                    },
                  ),
                );
              }),

              // Full interactions link
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _launchUrl(info.interactionsUrl),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View all drug interactions'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Side effect tile widget
// ─────────────────────────────────────────────

class _SideEffectTile extends StatelessWidget {
  final _SideEffect effect;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SideEffectTile({
    required this.effect,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final urgentBg = colorScheme.errorContainer;
    final normalBg = colorScheme.surfaceContainerHighest;

    final urgentFg = colorScheme.onErrorContainer;
    final normalFg = colorScheme.onSurface;

    final bg = isExpanded
        ? (effect.urgent ? urgentBg : colorScheme.secondaryContainer)
        : (effect.urgent
            ? urgentBg.withValues(alpha: 0.45)
            : normalBg);

    final fg = effect.urgent ? urgentFg : normalFg;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      effect.urgent ? Icons.warning_amber_rounded : Icons.info_outline,
                      size: 18,
                      color: effect.urgent ? colorScheme.error : colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        effect.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: fg,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: fg.withOpacity(0.6),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 8),
                  if (effect.urgent)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⚠ Needs medical attention',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Common — usually manageable',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    effect.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fg.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
